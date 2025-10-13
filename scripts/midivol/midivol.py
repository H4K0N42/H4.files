import rtmidi
import subprocess
import time
import re
import logging
import math

# Configuration
MIDI_CC = 0               # Master volume fader CC
MIDI_CC_BROWSER = 1       # Zen volume fader CC
MIDI_CC_SPOTIFY = 2       # Spotify volume fader CC
MIDI_CC_PHONE = 3
MIDI_CC_FOCUSED = 4
MIDI_CHANNEL = 0          # MIDI channel (0-indexed)

# Logging setup
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("midivol")

def set_volume(value):
    """Set master volume via amixer (0-127 mapped to 0-127%)."""
    percent = int(value)
    subprocess.run(["amixer", "set", "Master", f"{percent}%"],
                   stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)
    log.info(f"Set MASTER volume to {percent}%")

def get_stream_id_by_name(name_substring):
    """
    Search Audio → Streams for a stream containing name_substring (case-insensitive).
    Returns the stream ID as string or None if not found.
    """
    try:
        output = subprocess.check_output(["wpctl", "status"], text=True, stderr=subprocess.DEVNULL, timeout=2)

        in_audio_streams = False
        for line in output.splitlines():
            if re.match(r"\s*└─ Streams:", line):
                in_audio_streams = True
                continue
            if in_audio_streams:
                # Check if name_substring appears anywhere in line, case-insensitive
                if name_substring.lower() in line.lower():
                    match = re.match(r'^\s*(\d+)\.', line)
                    if match:
                        return match.group(1)
                # End of streams section if dedented
                if not line.startswith("   "):
                    break
    except subprocess.SubprocessError as e:
        log.warning(f"Failed to get stream ID for '{name_substring}': {e}")
    return None

def set_volume_for_stream(name_substring, volume):
    cache_attr_id = f"last_stream_id_{name_substring}"
    cache_attr_vol = f"last_volume_{name_substring}"

    if not hasattr(set_volume_for_stream, cache_attr_id):
        setattr(set_volume_for_stream, cache_attr_id, None)
        setattr(set_volume_for_stream, cache_attr_vol, None)

    stream_id = getattr(set_volume_for_stream, cache_attr_id)
    last_volume = getattr(set_volume_for_stream, cache_attr_vol)
    
    
    if stream_id is None:
        stream_id = get_stream_id_by_name(name_substring)
        setattr(set_volume_for_stream, cache_attr_id, stream_id)
        if stream_id is None:
            log.warning(f"Stream '{name_substring}' not found.")
            return

    if volume == last_volume:
        log.debug(f"{name_substring} volume unchanged at {volume}%, skipping.")
        return

    try:
        subprocess.run(["wpctl", "set-volume", stream_id, str(volume / 100)],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        setattr(set_volume_for_stream, cache_attr_vol, volume)
        log.info(f"Set {name_substring} volume to {volume}% (Stream ID {stream_id})")
    except subprocess.CalledProcessError as e:
        log.error(f"wpctl set-volume failed for {name_substring}: {e}")
        setattr(set_volume_for_stream, cache_attr_id, None)  # Invalidate cache

def get_focused_window_app_name_hyprland():
    """Return the focused window class by parsing hyprctl activewindow output."""
    try:
        output = subprocess.check_output(["hyprctl", "activewindow"], text=True)
        for line in output.splitlines():
            line = line.strip()
            if line.startswith("class:"):
                # Get everything after "class:"
                class_name = line.split(":", 1)[1].strip()
                # If the class has dots, return after last dot (optional)
                if '.' in class_name:
                    class_name = class_name.split('.')[-1]
                return class_name.lower()
    except subprocess.SubprocessError:
        log.warning("Failed to get focused window application name via hyprctl.")
    return None

def set_volume_for_focused_app(volume):
    app_name = get_focused_window_app_name_hyprland()
    if app_name is None:
        log.warning("No focused window app detected.")
        return

    cache_attr_id = f"last_stream_id_focused"
    cache_attr_vol = f"last_volume_focused"

    if not hasattr(set_volume_for_focused_app, cache_attr_id):
        setattr(set_volume_for_focused_app, cache_attr_id, None)
        setattr(set_volume_for_focused_app, cache_attr_vol, None)

    stream_id = getattr(set_volume_for_focused_app, cache_attr_id)
    last_volume = getattr(set_volume_for_focused_app, cache_attr_vol)

    # Invalidate cache if the app changed
    if stream_id is None:
        stream_id = get_stream_id_by_name(app_name)
        setattr(set_volume_for_focused_app, cache_attr_id, stream_id)
        if stream_id is None:
            log.warning(f"Stream for focused app '{app_name}' not found.")
            return

    if volume == last_volume:
        log.debug(f"Focused app volume unchanged at {volume}%, skipping.")
        return

    try:
        subprocess.run(["wpctl", "set-volume", stream_id, str(volume / 100)],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        setattr(set_volume_for_focused_app, cache_attr_vol, volume)
        log.info(f"Set focused app '{app_name}' volume to {volume}% (Stream ID {stream_id})")
    except subprocess.CalledProcessError as e:
        log.error(f"wpctl set-volume failed for focused app '{app_name}': {e}")
        setattr(set_volume_for_focused_app, cache_attr_id, None)  # Invalidate cache

def exp_scale(value, max_value=100, gamma=2):
    """
    Apply exponential scaling to a linear input value.
    
    gamma < 1 expands low values, giving finer control in quiet range.
    
    Args:
        value (int): Input linear value (0 to max_value)
        max_value (int): Maximum possible input value (default 127)
        gamma (float): Exponent <1 to expand low values, >1 to compress
    
    Returns:
        int: Scaled value in range 0 to max_value
    """
    if value <= 0:
        return 0
    if value > max_value:
        value = max_value
    normalized = value / max_value
    scaled = normalized ** gamma
    return int(round(scaled * max_value))

def midi_callback(event, data=None):
    message, _ = event
    if message[0] == 0xB0 + MIDI_CHANNEL:
        cc = message[1]
        #val = exp_scale(int(message[2]))
        val = int(message[2])
        if cc == MIDI_CC:
            set_volume(val)  # Master volume
        elif cc == MIDI_CC_BROWSER:
            set_volume_for_stream("Zen", val)
        elif cc == MIDI_CC_SPOTIFY:
            set_volume_for_stream("spotify", val)
        elif cc == MIDI_CC_FOCUSED:
            set_volume_for_focused_app(val)
        elif cc == MIDI_CC_PHONE:
            set_volume_for_stream("bluez_input", val)

# MIDI setup
midi_in = rtmidi.MidiIn()
ports = midi_in.get_ports()

if len(ports) < 2:
    log.error("Not enough MIDI ports available (need port 1).")
    exit(1)

midi_in.open_port(1)
midi_in.set_callback(midi_callback)

log.info("Listening for MIDI CC... Press Ctrl+C to exit.")

try:
    while True:
        time.sleep(0.1)  # avoid busy wait
except KeyboardInterrupt:
    log.info("Exiting.")
finally:
    midi_in.close_port()

