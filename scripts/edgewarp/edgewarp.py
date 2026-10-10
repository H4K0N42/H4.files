"""Physically correct cursor crossing between two stacked monitors under niri.

niri maps the cursor through logical pixels, so a 1440p and a 1080p panel of
the same physical width don't line up at their shared edge. The outputs touch
in outputs.kdl, so niri moves the cursor across by itself; this puts an
invisible STRIP px tall layer-shell strip on both touching edges, and when the
cursor leaves a strip through the edge, it is warped via a virtual pointer to
the same relative x on the other monitor, keeping its y there. Where the edge
doesn't touch the other monitor (the outer parts of the wider one), niri holds
the cursor on the edge row, and pushing against it warps too.

Best effort: a client only sees the cursor while it's over its own surfaces, so
whether and where it crossed is extrapolated from the last motion on the strip.

Strips sit on the top layer, so a fullscreen window covers them and crossing
is off on that output while it's fullscreen (keeps games' pointer capture).
"""

import json
import os
import subprocess
import time

from pywayland.client import Display

from wlproto.wayland import WlCompositor, WlOutput, WlSeat, WlShm
from wlproto.cursor_shape_v1 import WpCursorShapeManagerV1
from wlproto.relative_pointer_unstable_v1 import ZwpRelativePointerManagerV1
from wlproto.wlr_layer_shell_unstable_v1 import ZwlrLayerShellV1, ZwlrLayerSurfaceV1
from wlproto.wlr_virtual_pointer_unstable_v1 import ZwlrVirtualPointerManagerV1

UPPER = "DP-2"
LOWER = "DP-1"

STRIP = 10  # px; tall enough that a fast flick still lands on it once

CURSOR_SHAPE_DEFAULT = 1


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


class EdgeWarp:
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
        rel_manager = registry.bind(g["zwp_relative_pointer_manager_v1"][0], ZwpRelativePointerManagerV1, 1)
        shape_manager = registry.bind(g["wp_cursor_shape_manager_v1"][0], WpCursorShapeManagerV1, 1)

        for name, ver in g["wl_output"]:
            wl_output = registry.bind(name, WlOutput, 4)
            wl_output.dispatcher["name"] = lambda o, n: self.outputs.__setitem__(n, o)
        self.display.roundtrip()

        self.pointer = self.seat.get_pointer()
        self.pointer.dispatcher["enter"] = self.on_enter
        self.pointer.dispatcher["leave"] = self.on_leave
        self.pointer.dispatcher["motion"] = self.on_motion
        self.relative = rel_manager.get_relative_pointer(self.pointer)
        self.relative.dispatcher["relative_motion"] = self.on_relative_motion
        self.cursor_shape = shape_manager.get_pointer(self.pointer)

        self.keepalive = []
        self.make_strip(LOWER, UPPER, ZwlrLayerSurfaceV1.anchor.top, -1)
        self.make_strip(UPPER, LOWER, ZwlrLayerSurfaceV1.anchor.bottom, +1)

        self.active = None  # strip the cursor is on
        self.x = self.y = 0.0  # last position on it
        self.dx = self.dy = 0.0  # last motion on it

    def on_global(self, registry, name, interface, version):
        if interface == "wl_output":
            self.globals.setdefault(interface, []).append((name, version))
        else:
            self.globals[interface] = (name, version)

    def make_strip(self, output, other, edge, direction):
        """Transparent strip along `edge` of `output`; `direction` points at `other`."""
        anchor = ZwlrLayerSurfaceV1.anchor
        surface = self.compositor.create_surface()
        # top, not overlay: niri draws fullscreen windows above the top layer
        layer = self.layer_shell.get_layer_surface(
            surface, self.outputs[output], ZwlrLayerShellV1.layer.top, "edgewarp"
        )
        layer.set_anchor(edge | anchor.left | anchor.right)
        layer.set_size(0, STRIP)
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
            self.keepalive.append(buffer)

        layer.dispatcher["configure"] = configure
        layer.dispatcher["closed"] = lambda l: os._exit(1)
        surface.commit()
        # (output it sits on, output it warps to, direction towards it)
        surface.user_data = (output, other, direction)
        self.keepalive += [surface, layer]

    def on_enter(self, pointer, serial, surface, sx, sy):
        self.active = surface.user_data
        self.x, self.y = sx, sy
        self.dx = self.dy = 0.0
        self.cursor_shape.set_shape(serial, CURSOR_SHAPE_DEFAULT)

    def on_motion(self, pointer, time_ms, sx, sy):
        self.x, self.y = sx, sy

    def on_relative_motion(self, rel, utime_hi, utime_lo, dx, dy, dx_unaccel, dy_unaccel):
        self.dx, self.dy = dx, dy
        if self.active is None:
            return
        output, target, direction = self.active
        # pushing against the edge row where niri won't move the cursor across
        if self.to_edge(direction) <= 1 and dy * direction > 0:
            self.active = None
            self.cross(output, target, direction, 0)

    def on_leave(self, pointer, serial, surface):
        # The motion that caused the leave goes to whatever is under the cursor
        # now, so assume it was like the last one we saw.
        if self.active is None:
            return
        output, target, direction = self.active
        self.active = None
        to_edge = self.to_edge(direction)
        if self.dy * direction <= 0 or to_edge > 2 * abs(self.dy) + 2:
            return  # left back inwards, or something covered the strip
        # how far past the edge it went, measured into the target
        self.cross(output, target, direction, max(self.dy * direction - to_edge, 0))

    def to_edge(self, direction) -> float:
        return STRIP - self.y if direction > 0 else self.y

    def cross(self, output, target, direction, past):
        outs = niri_outputs()
        src, dst = outs[output], outs[target]
        x = min(max((self.x + self.dx) / src["width"], 0), 1) * dst["width"]
        y = past if direction > 0 else dst["height"] - 1 - past
        print(f"{output} x={self.x:.0f} -> {target} x={x:.0f} y={y:.0f}", flush=True)
        self.warp(target, dst, x, y)

    def warp(self, output: str, logical: dict, x: float, y: float):
        """Put the cursor at output-local logical (x, y)."""
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

    def run(self):
        while self.display.dispatch(block=True) != -1:
            pass


if __name__ == "__main__":
    EdgeWarp().run()
