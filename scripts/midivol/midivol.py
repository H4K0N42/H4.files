import json
import logging
import os
import subprocess
import threading
import time

import rtmidi

# Configuration
MIDI_PORT_NAME = "Arduino Leonardo"  # substring of the rtmidi port name
MIDI_CHANNEL = 0                     # MIDI channel (0-indexed)
RECONNECT_INTERVAL = 2               # seconds between checks for a (re)plugged device
FADER_MAX = 100                      # CC value the faders send at the top (not 127)
WATCH_INTERVAL = 1                   # seconds between checks for new streams
# last position of each fader; the device only sends on movement, so this is
# what gets applied after a restart and to streams that appear later
STATE_FILE = os.path.expanduser("~/.local/state/midivol.json")

# Fader curve, in dB so it matches how loudness is perceived:
#   level = MAX_DB - RANGE_DB * (1 - f**CURVE)    f = fader position 0..1, f=0 mutes
# CURVE > 1 makes big steps near the top and fine control near the bottom;
# CURVE = 1 is evenly spaced in dB.
MAX_DB = 0
RANGE_DB = 50
CURVE = 1

MASTER = "master"
FOCUSED = "focused"

# CC -> what the fader controls. Stream matchers are (pipewire prop, substring),
# case-insensitive; every stream matching any of them is set.
FADERS = {
    0: MASTER,
    1: [("application.name", "zen"), ("application.process.binary", "zen")],
    2: [("application.process.binary", "tidal-hifi")],
    3: [("node.name", "bluez_input")],
    4: FOCUSED,
}

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("midivol")


def audio_streams() -> list[tuple[int, dict]]:
    """All playback streams (and bluetooth inputs) as (node id, props)."""
    try:
        dump = json.loads(subprocess.check_output(["pw-dump"], timeout=2))
    except (subprocess.SubprocessError, json.JSONDecodeError) as e:
        log.warning(f"pw-dump failed: {e}")
        return []
    streams = []
    for obj in dump:
        props = (obj.get("info") or {}).get("props") or {}
        media_class = str(props.get("media.class", ""))
        if media_class == "Stream/Output/Audio" or str(props.get("node.name", "")).startswith("bluez_input"):
            streams.append((obj["id"], props))
    return streams


def ancestors(pid: int) -> set[int]:
    """pid and all its parent pids (browsers play audio from child processes)."""
    pids = set()
    while pid > 1 and pid not in pids:
        pids.add(pid)
        try:
            with open(f"/proc/{pid}/stat") as f:
                # field 4 is ppid; comm (field 2) may contain spaces, so split after ')'
                pid = int(f.read().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            break
    return pids


def focused_window() -> dict | None:
    try:
        return json.loads(subprocess.check_output(["niri", "msg", "--json", "focused-window"], timeout=2))
    except (subprocess.SubprocessError, json.JSONDecodeError) as e:
        log.warning(f"niri focused-window failed: {e}")
        return None


def matches(props: dict, matchers: list[tuple[str, str]]) -> bool:
    return any(needle in str(props.get(prop, "")).lower() for prop, needle in matchers)


def matching_streams(target) -> list[int]:
    streams = audio_streams()
    if target == FOCUSED:
        window = focused_window()
        if not window:
            return []
        # apps with their own fader stay out of reach of the focused fader
        dedicated = [m for m in FADERS.values() if isinstance(m, list)]
        app_id = (window.get("app_id") or "").lower()
        ids = []
        for node_id, props in streams:
            if any(matches(props, m) for m in dedicated):
                continue
            pid = props.get("application.process.id")
            if (pid and window.get("pid") in ancestors(int(pid))) or (
                app_id and app_id in str(props.get("application.name", "")).lower()
            ):
                ids.append(node_id)
        return ids
    return [node_id for node_id, props in streams if matches(props, target)]


def fader_to_db(value: int) -> float | None:
    """MIDI value 0..FADER_MAX -> level in dB, None for mute."""
    if value <= 0:
        return None
    f = min(value / FADER_MAX, 1)
    return MAX_DB - RANGE_DB * (1 - f**CURVE)


def db_to_wpctl(db: float | None) -> float:
    # wpctl volumes are cubic: amplitude = v**3, i.e. dB = 60 * log10(v)
    return 0.0 if db is None else 10 ** (db / 60)


def set_volume(node: str, volume: float):
    # a stream can vanish between pw-dump and here; nothing to do then
    subprocess.run(["wpctl", "set-volume", node, f"{volume:.4f}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def apply(cc: int, value: int):
    target = FADERS[cc]
    db = fader_to_db(value)
    volume = db_to_wpctl(db)
    level = "mute" if db is None else f"{db:.1f} dB"

    if target == MASTER:
        set_volume("@DEFAULT_AUDIO_SINK@", volume)
        log.info(f"Set MASTER volume to {level}")
        return

    ids = matching_streams(target)
    if not ids:
        log.warning(f"CC {cc}: no matching stream")
        return
    for node_id in ids:
        set_volume(str(node_id), volume)
    log.info(f"CC {cc}: set {level} on streams {ids}")


class FaderState:
    """Last known value per CC, persisted across restarts."""

    def __init__(self):
        self.lock = threading.Lock()
        try:
            with open(STATE_FILE) as f:
                self.values = {int(cc): v for cc, v in json.load(f).items() if int(cc) in FADERS}
        except (OSError, ValueError):
            self.values = {}

    def get(self) -> dict[int, int]:
        with self.lock:
            return dict(self.values)

    def update(self, batch: dict[int, int]):
        with self.lock:
            self.values.update({cc: v for cc, v in batch.items() if FADERS[cc] != FOCUSED})
            values = dict(self.values)
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(values, f)
        os.replace(tmp, STATE_FILE)


state = FaderState()


def watch_streams():
    """Give streams that show up later (app restarted, new tab playing, ...) the
    level of their fader. The first pass also restores everything at startup."""
    known: set[int] | None = None
    while True:
        streams = audio_streams()
        values = state.get()
        if known is None and 0 in values and FADERS[0] == MASTER:
            try:
                apply(0, values[0])
            except Exception:
                log.exception("failed to restore master")
        for node_id, props in streams:
            if known is not None and node_id in known:
                continue
            for cc, target in FADERS.items():
                if isinstance(target, list) and cc in values and matches(props, target):
                    set_volume(str(node_id), db_to_wpctl(fader_to_db(values[cc])))
                    log.info(f"CC {cc}: restored value {values[cc]} on new stream {node_id}")
        known = {node_id for node_id, _ in streams}
        time.sleep(WATCH_INTERVAL)


class Coalescer:
    """Keeps only the newest value per CC and applies it in a worker thread,
    so a fast fader never blocks the MIDI callback and the final position is
    never dropped."""

    def __init__(self):
        self.pending: dict[int, int] = {}
        self.cond = threading.Condition()
        threading.Thread(target=self.worker, daemon=True).start()

    def submit(self, cc: int, value: int):
        with self.cond:
            self.pending[cc] = value
            self.cond.notify()

    def worker(self):
        while True:
            with self.cond:
                while not self.pending:
                    self.cond.wait()
                batch, self.pending = self.pending, {}
            for cc, value in batch.items():
                try:
                    apply(cc, value)
                except Exception:
                    log.exception(f"CC {cc}: failed to apply {value}")
            try:
                state.update(batch)
            except OSError:
                log.exception("failed to save fader state")


coalescer = Coalescer()


def midi_callback(event, data=None):
    message, _ = event
    if len(message) == 3 and message[0] == 0xB0 + MIDI_CHANNEL and message[1] in FADERS:
        coalescer.submit(message[1], int(message[2]))


def find_port(midi_in: rtmidi.MidiIn) -> tuple[int, str] | None:
    for i, name in enumerate(midi_in.get_ports()):
        if MIDI_PORT_NAME in name:
            return i, name
    return None


def main():
    midi_in = rtmidi.MidiIn()
    midi_in.set_callback(midi_callback)
    connected = None  # port name while open
    threading.Thread(target=watch_streams, daemon=True).start()

    log.info(f"Waiting for MIDI port '{MIDI_PORT_NAME}'...")
    try:
        while True:
            port = find_port(midi_in)
            if connected and (port is None or port[1] != connected):
                log.warning(f"MIDI port '{connected}' disappeared")
                midi_in.close_port()
                connected = None
            if not connected and port is not None:
                midi_in.open_port(port[0])
                connected = port[1]
                log.info(f"Listening on '{connected}'")
            time.sleep(RECONNECT_INTERVAL)
    except KeyboardInterrupt:
        log.info("Exiting.")
    finally:
        midi_in.close_port()


if __name__ == "__main__":
    main()
