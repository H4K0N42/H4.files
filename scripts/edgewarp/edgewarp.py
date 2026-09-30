"""Physically correct cursor crossing between two stacked monitors under niri.

niri maps the cursor through logical pixels, so a 1440p and a 1080p panel of
the same physical width don't line up at their shared edge. This puts an
invisible 1 px layer-shell strip on the touching edges. When the cursor is
pushed against a strip (seen through relative-pointer, since the cursor itself
is clamped), it is warped via a virtual pointer to the same relative x on the
other monitor.

Needs the two outputs to NOT be adjacent in niri (leave a gap in outputs.kdl),
otherwise niri moves the cursor across by itself before a strip can catch it.

The gap blocks dragging windows across (the strips get no events during a
grab), so while Super + left mouse button is held (niri's Mod+drag) the upper
output is temporarily moved flush against the lower one, and put back on release.
"""

import fcntl
import json
import os
import select
import subprocess
import threading
import time

from pywayland.client import Display

from wlproto.wayland import WlCompositor, WlOutput, WlSeat, WlShm
from wlproto.cursor_shape_v1 import WpCursorShapeManagerV1
from wlproto.relative_pointer_unstable_v1 import ZwpRelativePointerManagerV1
from wlproto.wlr_layer_shell_unstable_v1 import ZwlrLayerShellV1, ZwlrLayerSurfaceV1
from wlproto.wlr_virtual_pointer_unstable_v1 import ZwlrVirtualPointerManagerV1

UPPER = "DP-2"
LOWER = "DP-1"

CURSOR_SHAPE_DEFAULT = 1

KEY_LEFTMETA, KEY_RIGHTMETA, BTN_LEFT = 125, 126, 272
KEY_BITMAP_BYTES = 96  # KEY_MAX 0x2ff
EVIOCGKEY = (2 << 30) | (KEY_BITMAP_BYTES << 16) | (ord("E") << 8) | 0x18
BUTTON_POLL = 0.01     # while Super is held
RESCAN_INTERVAL = 5    # look for replugged keyboards/mice


def niri_outputs() -> dict[str, dict]:
    out = subprocess.run(["niri", "msg", "--json", "outputs"], capture_output=True, text=True, check=True).stdout
    return {name: o["logical"] for name, o in json.loads(out).items() if o.get("logical")}


def to_panel(logical: dict, x: float, y: float) -> tuple[float, float]:
    """An output-bound virtual pointer takes untransformed panel coordinates."""
    w, h = logical["width"], logical["height"]
    match logical["transform"]:
        case "Normal":
            return x, y
        case "180":
            return w - x, h - y
        case "Flipped":
            return w - x, y
        case "Flipped180":
            return x, h - y
    raise NotImplementedError(f"transform {logical['transform']}")


def input_devices() -> tuple[list[str], list[str]]:
    """(keyboards with a Super key, devices with a left mouse button) from /proc."""
    keyboards, mice = [], []
    with open("/proc/bus/input/devices") as f:
        blocks = f.read().split("\n\n")
    for block in blocks:
        handlers, keybits = [], 0
        for line in block.splitlines():
            if line.startswith("H: Handlers="):
                handlers = line.split("=", 1)[1].split()
            elif line.startswith("B: KEY="):
                # space separated 64-bit words, most significant first
                for word in line.split("=", 1)[1].split():
                    keybits = (keybits << 64) | int(word, 16)
        event = next((h for h in handlers if h.startswith("event")), None)
        if event is None:
            continue
        path = f"/dev/input/{event}"
        if keybits >> KEY_LEFTMETA & 1 or keybits >> KEY_RIGHTMETA & 1:
            keyboards.append(path)
        if keybits >> BTN_LEFT & 1:
            mice.append(path)
    return keyboards, mice


def keys_down(fd: int, *codes: int) -> bool:
    state = bytearray(KEY_BITMAP_BYTES)
    try:
        fcntl.ioctl(fd, EVIOCGKEY, state)
    except OSError:
        return False
    return any(state[c // 8] >> (c % 8) & 1 for c in codes)


class DragBridge:
    """Closes the gap between the outputs while Super + left button is held."""

    def __init__(self):
        self.wl = WaylandClient()
        self.fds: dict[str, int] = {}
        self.keyboards: list[str] = []
        self.mice: list[str] = []
        self.gap_pos: tuple[int, int] | None = None  # set while bridged
        threading.Thread(target=self.run, daemon=True).start()

    def rescan(self):
        keyboards, mice = input_devices()
        for path in set(keyboards) | set(mice):
            if path not in self.fds:
                try:
                    self.fds[path] = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
                except OSError:
                    continue
        for path in list(self.fds):
            if path not in keyboards and path not in mice:
                os.close(self.fds.pop(path))
        self.keyboards = [p for p in keyboards if p in self.fds]
        self.mice = [p for p in mice if p in self.fds]

    def pressed(self, devices, *codes) -> bool:
        return any(keys_down(self.fds[p], *codes) for p in devices if p in self.fds)

    def bridge(self):
        outs = niri_outputs()
        upper, lower = outs[UPPER], outs[LOWER]
        self.gap_pos = (upper["x"], upper["y"])
        x = lower["x"] + (lower["width"] - upper["width"]) // 2
        set_position(UPPER, x, lower["y"] - upper["height"])

    def unbridge(self):
        # Moving UPPER away would leave a cursor that is on it in the gap, and
        # niri then drops it in the middle of LOWER. So find out where it is
        # first, and put it back on UPPER afterwards.
        pos = self.probe_cursor(UPPER)
        set_position(UPPER, *self.gap_pos)
        self.gap_pos = None
        if pos is not None:
            self.wl.warp(UPPER, *pos)

    def probe_cursor(self, output: str, timeout: float = 0.1) -> tuple[float, float] | None:
        """Cursor position on `output` via a short-lived full-screen overlay."""
        wl = self.wl
        found = []
        configured = []
        pointer = wl.seat.get_pointer()
        pointer.dispatcher["enter"] = lambda p, serial, surf, sx, sy: found.append((sx, sy))
        anchor = ZwlrLayerSurfaceV1.anchor
        surface, layer = wl.layer_surface(
            output, anchor.top | anchor.bottom | anchor.left | anchor.right, 0, lambda: configured.append(1)
        )
        deadline = time.monotonic() + timeout
        nudged = False
        while not found and time.monotonic() < deadline:
            wl.display.roundtrip()
            if configured and not nudged:
                # niri updates pointer focus on motion; a zero net move triggers it
                vp = wl.vp_manager.create_virtual_pointer(wl.seat)
                t = int(time.monotonic() * 1000) & 0xFFFFFFFF
                vp.motion(t, 1, 0)
                vp.frame()
                vp.motion(t, -1, 0)
                vp.frame()
                vp.destroy()
                nudged = True
            time.sleep(0.005)

        wl.destroy_layer_surface(surface, layer)
        pointer.release()
        wl.display.roundtrip()
        return found[0] if found else None

    def run(self):
        self.rescan()
        last_scan = time.monotonic()
        while True:
            super_held = self.pressed(self.keyboards, KEY_LEFTMETA, KEY_RIGHTMETA)
            if self.gap_pos is not None:
                # bridged: hold until the drag ends, Super may be let go earlier
                if not self.pressed(self.mice, BTN_LEFT):
                    self.unbridge()
                time.sleep(BUTTON_POLL)
            elif super_held:
                if self.pressed(self.mice, BTN_LEFT):
                    self.bridge()
                time.sleep(BUTTON_POLL)
            else:
                # idle: sleep until a key event arrives, no polling
                fds = [self.fds[p] for p in self.keyboards]
                ready, _, _ = select.select(fds, [], [], RESCAN_INTERVAL)
                for fd in ready:
                    try:
                        while os.read(fd, 4096):
                            pass
                    except BlockingIOError:
                        pass
                    except OSError:
                        pass  # unplugged, next rescan drops it
            if time.monotonic() - last_scan > RESCAN_INTERVAL:
                self.rescan()
                last_scan = time.monotonic()


def set_position(output: str, x: int, y: int):
    subprocess.run(["niri", "msg", "output", output, "position", "set", "--", str(x), str(y)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


class WaylandClient:
    """One connection with the globals both EdgeWarp and DragBridge need."""

    def __init__(self):
        self.display = Display()
        self.display.connect()

        self.globals = {}
        self.outputs = {}  # name -> wl_output
        self.registry = registry = self.display.get_registry()
        registry.dispatcher["global"] = self.on_global
        self.display.roundtrip()

        g = self.globals
        self.compositor = registry.bind(g["wl_compositor"][0], WlCompositor, 4)
        self.shm = registry.bind(g["wl_shm"][0], WlShm, 1)
        self.seat = registry.bind(g["wl_seat"][0], WlSeat, 5)
        self.layer_shell = registry.bind(g["zwlr_layer_shell_v1"][0], ZwlrLayerShellV1, 4)
        self.vp_manager = registry.bind(g["zwlr_virtual_pointer_manager_v1"][0], ZwlrVirtualPointerManagerV1, 2)

        for name, ver in g["wl_output"]:
            wl_output = registry.bind(name, WlOutput, 4)
            wl_output.dispatcher["name"] = lambda o, n: self.outputs.__setitem__(n, o)
        self.display.roundtrip()

        self.keepalive = []
        self.buffers = {}  # surface -> its current buffer

    def on_global(self, registry, name, interface, version):
        if interface == "wl_output":
            self.globals.setdefault(interface, []).append((name, version))
        else:
            self.globals[interface] = (name, version)

    def layer_surface(self, output, anchor, height, on_configured=None):
        """Transparent overlay layer surface; height 0 = full output."""
        surface = self.compositor.create_surface()
        layer = self.layer_shell.get_layer_surface(
            surface, self.outputs[output], ZwlrLayerShellV1.layer.overlay, "edgewarp"
        )
        layer.set_anchor(anchor)
        layer.set_size(0, height)
        layer.set_exclusive_zone(-1)  # sit on the very edge, ignore the bar's zone
        layer.set_keyboard_interactivity(0)

        def configure(l, serial, width, height):
            l.ack_configure(serial)
            size = width * height * 4
            fd = os.memfd_create("edgewarp")
            os.ftruncate(fd, size)  # zero-filled = fully transparent argb8888
            pool = self.shm.create_pool(fd, size)
            buffer = pool.create_buffer(0, width, height, width * 4, WlShm.format.argb8888.value)
            pool.destroy()
            os.close(fd)
            surface.attach(buffer, 0, 0)
            surface.damage_buffer(0, 0, width, height)
            surface.commit()
            self.buffers[surface] = buffer
            if on_configured:
                on_configured()

        layer.dispatcher["configure"] = configure
        layer.dispatcher["closed"] = lambda l: os._exit(1)
        surface.commit()
        self.keepalive += [surface, layer]
        return surface, layer

    def destroy_layer_surface(self, surface, layer):
        layer.destroy()
        surface.destroy()
        if buffer := self.buffers.pop(surface, None):
            buffer.destroy()
        for obj in (surface, layer):
            self.keepalive.remove(obj)

    def warp(self, output: str, x: float, y: float):
        """Put the cursor at output-local logical (x, y)."""
        logical = niri_outputs()[output]
        w, h = logical["width"], logical["height"]
        # a point exactly on the far edge lies outside the output and niri drops
        # the cursor somewhere else
        x, y = min(max(x, 1), w - 2), min(max(y, 1), h - 2)
        x, y = to_panel(logical, x, y)
        vp = self.vp_manager.create_virtual_pointer_with_output(self.seat, self.outputs[output])
        vp.motion_absolute(int(time.monotonic() * 1000) & 0xFFFFFFFF, int(x), int(y), w, h)
        vp.frame()
        vp.destroy()
        self.display.flush()


class EdgeWarp(WaylandClient):
    def __init__(self):
        super().__init__()
        self.logical = niri_outputs()
        g = self.globals
        rel_manager = self.registry.bind(g["zwp_relative_pointer_manager_v1"][0], ZwpRelativePointerManagerV1, 1)
        shape_manager = self.registry.bind(g["wp_cursor_shape_manager_v1"][0], WpCursorShapeManagerV1, 1)

        self.pointer = self.seat.get_pointer()
        self.pointer.dispatcher["enter"] = self.on_enter
        self.pointer.dispatcher["leave"] = self.on_leave
        self.pointer.dispatcher["motion"] = self.on_motion
        self.relative = rel_manager.get_relative_pointer(self.pointer)
        self.relative.dispatcher["relative_motion"] = self.on_relative_motion
        self.cursor_shape = shape_manager.get_pointer(self.pointer)

        self.make_strip(LOWER, UPPER, ZwlrLayerSurfaceV1.anchor.top, -1)
        self.make_strip(UPPER, LOWER, ZwlrLayerSurfaceV1.anchor.bottom, +1)

        self.active = None  # strip the cursor is currently on
        self.x = 0.0

    def make_strip(self, output, target, edge, direction):
        anchor = ZwlrLayerSurfaceV1.anchor
        surface, _ = self.layer_surface(output, edge | anchor.left | anchor.right, 1)
        # (output it sits on, output it warps to, push direction)
        surface.user_data = (output, target, direction)

    def on_enter(self, pointer, serial, surface, sx, sy):
        self.active = surface.user_data
        self.x = sx
        self.cursor_shape.set_shape(serial, CURSOR_SHAPE_DEFAULT)

    def on_leave(self, pointer, serial, surface):
        self.active = None

    def on_motion(self, pointer, time_ms, sx, sy):
        self.x = sx

    def on_relative_motion(self, rel, utime_hi, utime_lo, dx, dy, dx_unaccel, dy_unaccel):
        if self.active is None:
            return
        output, target, direction = self.active
        if dy * direction <= 0:
            return
        self.active = None  # one warp per enter

        src, dst = self.logical[output], self.logical[target]
        x = self.x / src["width"] * dst["width"]
        # land just inside the target, past its strip
        y = dst["height"] - 2 if direction < 0 else 1
        print(f"{output} x={self.x:.0f} -> {target} x={x:.0f}", flush=True)
        self.warp(target, x, y)

    def run(self):
        while self.display.dispatch(block=True) != -1:
            pass


if __name__ == "__main__":
    DragBridge()
    EdgeWarp().run()
