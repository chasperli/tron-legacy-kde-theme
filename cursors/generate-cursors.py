#!/usr/bin/env python3
"""
Tron Legacy — Cursor Theme Generator

Two jobs:

  python3 cursors/generate-cursors.py
      Writes the SVG sources (cursors/TronLegacy_cursors/cursors_scalable/).
      These are committed. KWin (Plasma 6, Wayland) renders them directly.

  python3 cursors/generate-cursors.py --xcursor <theme-dir>
      Renders the SVG sources into binary Xcursor files in <theme-dir>/cursors/
      for X11 / XWayland apps. Run by install.sh. Needs librsvg + cairo
      (package "librsvg"), loaded via ctypes — no Python modules required.

Every cursor is drawn on a 32×32 canvas with nominal size 24 (same convention
as breeze_cursors). Shapes are drawn as a "silhouette": a dark halo, a cyan
edge and a dark core, so overlapping parts merge into one outline and the
cursor stays visible on light backgrounds. No SVG filters (QtSvg can't).
"""

import argparse
import ctypes
import json
import math
import shutil
import struct
import sys
from pathlib import Path

THEME = Path(__file__).resolve().parent / "TronLegacy_cursors"
SCALABLE = THEME / "cursors_scalable"

# ── Canonical palette (keep in sync with AGENTS.md) ─────────────────────────
BG = "#050A0E"
CARD = "#0A141E"
CYAN = "#00F5FF"
HALO = "#003848"
ORANGE = "#FF9500"
RED = "#FF3030"
GREEN = "#00C8A0"

EDGE = 1.4     # cyan edge thickness per side
GLOW = 1.3     # halo thickness per side, outside the edge
NOMINAL = 24
CANVAS = 32
XCURSOR_SIZES = (24, 36, 48, 72)   # → 32, 48, 64, 96 px images


# ── Geometry helpers ─────────────────────────────────────────────────────────
def poly(points):
    return "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in points) + " Z"


def rotate(points, deg, cx=16, cy=16):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c)
            for x, y in points]


def rot_pt(pt, deg):
    return rotate([pt], deg)[0]


def ring(cx, cy, r):
    return f"M{cx - r} {cy} A{r} {r} 0 1 0 {cx + r} {cy} A{r} {r} 0 1 0 {cx - r} {cy}"


def arc(cx, cy, r, start, sweep):
    a0, a1 = math.radians(start), math.radians(start + sweep)
    x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
    x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
    large = 1 if sweep > 180 else 0
    return f"M{x0:.2f} {y0:.2f} A{r} {r} 0 {large} 1 {x1:.2f} {y1:.2f}"


# ── Drawing primitives ───────────────────────────────────────────────────────
def F(d):
    """Filled closed shape."""
    return ("fill", d, 0)


def L(d, w):
    """Stroked line of width w (round caps)."""
    return ("line", d, w)


def silhouette(shapes, core=CARD, edge=CYAN, halo=HALO):
    layers = []
    for color, extra in ((halo, EDGE + GLOW), (edge, EDGE), (core, 0)):
        for kind, d, w in shapes:
            if kind == "fill":
                stroke = f'stroke="{color}" stroke-width="{2 * extra}"' if extra else 'stroke="none"'
                layers.append(f'<path d="{d}" fill="{color}" {stroke} stroke-linejoin="round"/>')
            else:
                layers.append(
                    f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w + 2 * extra}" '
                    f'stroke-linecap="round" stroke-linejoin="round"/>')
    return "".join(layers)


def stroke(d, color=CYAN, w=1.2, opacity=1):
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" '
            f'stroke-opacity="{opacity}" stroke-linecap="round" stroke-linejoin="round"/>')


def dot(cx, cy, r, color=CYAN):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{color}"/>'


def svg(*parts):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" '
            'viewBox="0 0 32 32">' + "".join(parts) + "</svg>\n")


# ── Shapes ───────────────────────────────────────────────────────────────────
ARROW = [(5, 4), (5, 23), (10, 18.6), (13.6, 26.2), (16.8, 24.8), (13.3, 17.4), (19.6, 17.4)]


def arrow(mirror=False):
    pts = [(32 - x, y) for x, y in ARROW] if mirror else ARROW
    accent = "M27 8.5 V17" if mirror else "M7 8.5 V17"
    return silhouette([F(poly(pts))]) + stroke(accent, CYAN, 1, 0.55)


def badge(glyph, color=CYAN):
    """Small round badge at the lower right of the arrow."""
    return (silhouette([F(ring(24, 24, 5.6))], CARD, color)
            + glyph)


BADGES = {
    "help": stroke("M21.9 22.4 C21.9 20.1 26.1 20.1 26.1 22.4 C26.1 23.9 24 24 24 25.6")
            + dot(24, 27.3, 0.9),
    "copy": stroke("M24 20.8 V27.2 M20.8 24 H27.2", GREEN, 1.6),
    "alias": stroke("M21 27 C21 23.3 22.5 22 26.5 22 M24.6 20.1 L26.5 22 L24.6 23.9", CYAN, 1.4),
    "context-menu": stroke("M21.2 21.8 H26.8 M21.2 24 H26.8 M21.2 26.2 H26.8", CYAN, 1.2),
    "no-drop": stroke(ring(24, 24, 3.2) + " M21.8 21.8 L26.2 26.2", RED, 1.4),
}


def arrow_with(name):
    color = {"copy": GREEN, "no-drop": RED}.get(name, CYAN)
    return svg(arrow() + badge(BADGES[name], color))


HAND_POINT = ("M11 13 V5.5 C11 3.6 15 3.6 15 5.5 V12.5 L15.6 12.5 C17 12.2 18.6 12.6 19 13.6 "
              "C20.4 13.2 22 13.7 22.3 14.8 C23.8 14.5 25 15.3 25 16.8 V21 "
              "C25 25.5 22.5 28.5 18.5 28.5 H15.5 C13 28.5 11.8 27.4 10.5 25.6 "
              "L6.4 19.8 C5.6 18.6 6.8 17 8.4 17.8 L11 19.4 Z")
PALM = "M9 15 H24 V21 C24 25.5 21.5 28 18 28 H15 C12.5 28 11 26.5 9.5 24.5 L6.5 19.5 Z"


def pointer():
    return svg(silhouette([F(HAND_POINT)]),
               stroke("M15 13.5 V18 M19 14 V18.4 M22.3 15.2 V18.6", CYAN, 0.9, 0.5))


def hand(open_):
    if open_:
        fingers = [L("M11 15 V8.5", 3.2), L("M14.6 14 V6.5", 3.2),
                   L("M18.2 14 V7", 3.2), L("M21.8 15 V9.5", 3.2)]
    else:
        fingers = [L("M11 15.5 V13", 3.2), L("M14.6 14.5 V12", 3.2),
                   L("M18.2 14.5 V12", 3.2), L("M21.8 15.5 V13.5", 3.2)]
    return svg(silhouette(fingers + [L("M7.5 18.5 L10 21.5", 3.2), F(PALM)]))


DOUBLE = [(16, 3), (21.5, 9.5), (17.6, 9.5), (17.6, 22.5), (21.5, 22.5),
          (16, 29), (10.5, 22.5), (14.4, 22.5), (14.4, 9.5), (10.5, 9.5)]


def double_arrow(deg, bar=False):
    shapes = [F(poly(rotate(DOUBLE, deg)))]
    if bar:
        a, b = rot_pt((6, 16), deg), rot_pt((26, 16), deg)
        shapes.insert(0, L(f"M{a[0]:.2f} {a[1]:.2f} L{b[0]:.2f} {b[1]:.2f}", 2))
    return svg(silhouette(shapes))


MOVE = [(16, 3), (20, 8), (17.3, 8), (17.3, 14.7), (24, 14.7), (24, 12), (29, 16), (24, 20),
        (24, 17.3), (17.3, 17.3), (17.3, 24), (20, 24), (16, 29), (12, 24), (14.7, 24),
        (14.7, 17.3), (8, 17.3), (8, 20), (3, 16), (8, 12), (8, 14.7), (14.7, 14.7),
        (14.7, 8), (12, 8)]

SIMPLE_ARROW = [(16, 4), (24, 13), (18.5, 13), (18.5, 27), (13.5, 27), (13.5, 13), (8, 13)]


def simple_arrow(deg):
    return svg(silhouette([F(poly(rotate(SIMPLE_ARROW, deg)))]))


def text(vertical=False):
    d = ("M12.5 5 C14.5 5 16 5.5 16 7 C16 5.5 17.5 5 19.5 5 M16 7 V25 "
         "M12.5 27 C14.5 27 16 26.5 16 25 C16 26.5 17.5 27 19.5 27")
    shape = silhouette([L(d, 1.6)], CYAN, BG)
    if vertical:
        shape = f'<g transform="rotate(90 16 16)">{shape}</g>'
    return svg(shape)


def crosshair():
    d = "M16 3 V8.5 M16 23.5 V29 M3 16 H8.5 M23.5 16 H29 " + ring(16, 16, 6.5)
    return svg(silhouette([L(d, 1.2)], CYAN, BG), dot(16, 16, 1))


def not_allowed():
    d = ring(16, 16, 10) + " M8.9 8.9 L23.1 23.1"
    return svg(silhouette([L(d, 2.6)], RED, BG))


def pencil():
    body = [(4, 28), (6, 21), (22, 5), (27, 10), (11, 26)]
    return svg(silhouette([F(poly(body))]),
               '<path d="M4 28 L6 21 L11 26 Z" fill="%s"/>' % ORANGE,
               stroke("M19.5 7.5 L24.5 12.5", CYAN, 1.2, 0.8))


def color_picker():
    return svg(silhouette([L("M5 27 L17 15", 3), F(ring(22, 10, 5.2))]),
               stroke("M14.5 13 L19 17.5", CYAN, 1.4), dot(5, 27, 1.3, ORANGE))


def zoom(plus):
    glyph = "M9.5 13 H16.5" + (" M13 9.5 V16.5" if plus else "")
    return svg(silhouette([L("M19 19 L27 27", 3.5), F(ring(13, 13, 8))]),
               stroke(glyph, CYAN, 1.6))


PLUS = [(14, 5), (18, 5), (18, 14), (27, 14), (27, 18), (18, 18), (18, 27), (14, 27),
        (14, 18), (5, 18), (5, 14), (14, 14)]


def center_ptr():
    return svg(silhouette([F(poly([(16, 3), (24, 25), (16, 20.5), (8, 25)]))]))


# ── Animated: the identity disc spinner ─────────────────────────────────────
FRAMES = 12
FRAME_DELAY = 45   # ms


def disc(cx, cy, r, frame):
    turn = frame * 180 / FRAMES   # pattern repeats every 180°
    arcs = " ".join(arc(cx, cy, r * 0.62, turn + k * 180, 110) for k in (0, 1))
    return (silhouette([F(ring(cx, cy, r))], BG, CYAN)
            + stroke(arcs, CYAN, max(1.4, r * 0.2))
            + dot(cx, cy, r * 0.18))


def wait(frame):
    return svg(disc(16, 16, 11, frame))


def progress(frame):
    return svg(arrow(), disc(24, 24, 6, frame))


# ── Cursor table: base name → (frames, hotspot, aliases) ────────────────────
def static(content):
    return [content]


CURSORS = {
    "default": (static(svg(arrow())), (5, 4),
                ["arrow", "left_ptr", "top_left_arrow", "x-cursor", "wayland-cursor"]),
    "right_ptr": (static(svg(arrow(mirror=True))), (27, 4), []),
    "center_ptr": (static(center_ptr()), (16, 3), []),
    "pointer": (static(pointer()), (13, 4),
                ["hand1", "hand2", "pointing_hand",
                 "9d800788f1b08800ae810202380a0822", "e29285e634086352946a0e7090d73106"]),
    "help": (static(arrow_with("help")), (5, 4),
             ["question_arrow", "whats_this", "left_ptr_help",
              "5c6cd98b3f3ebcb1f9c7f1c204630408", "d9ce0ab605698f320427677b458ad60b"]),
    "copy": (static(arrow_with("copy")), (5, 4),
             ["dnd-copy", "1081e37283d90000800003c07f3ef6bf",
              "6407b0e94181790501fd1e167b474872", "b66166c04f8c3109214a4fbd64a50fc8"]),
    "alias": (static(arrow_with("alias")), (5, 4),
              ["link", "dnd-link", "3085a0e285430894940527032f8b26df",
               "640fb0e74195791501fd1ed57b41487f", "a2a266d0498c3104214a47bd64ab0fc8"]),
    "context-menu": (static(arrow_with("context-menu")), (5, 4), ["dnd-ask"]),
    "no-drop": (static(arrow_with("no-drop")), (5, 4), ["forbidden", "dnd-no-drop"]),
    "not-allowed": (static(not_allowed()), (16, 16),
                    ["crossed_circle", "circle", "pirate", "03b6e0fcb3499374a867c041f52298f0"]),
    "text": (static(text()), (16, 16), ["ibeam", "xterm"]),
    "vertical-text": (static(text(vertical=True)), (16, 16), []),
    "crosshair": (static(crosshair()), (16, 16), ["cross", "tcross"]),
    "color-picker": (static(color_picker()), (5, 27), []),
    "pencil": (static(pencil()), (4, 28), ["draft"]),
    "zoom-in": (static(zoom(True)), (13, 13), []),
    "zoom-out": (static(zoom(False)), (13, 13), []),
    "plus": (static(svg(silhouette([F(poly(PLUS))]))), (16, 16), ["cell"]),
    "openhand": (static(hand(open_=True)), (16, 16), ["grab"]),
    "grabbing": (static(hand(open_=False)), (16, 16),
                 ["closedhand", "dnd-move", "dnd-none", "4498f0e0c1937ffe01fd06f973665830",
                  "9081237383d90e509aa00f00170e968f", "fcf21c00b30f7e3f83fe0dfd12e71cff"]),
    "move": (static(svg(silhouette([F(poly(MOVE))]))), (16, 16),
             ["fleur", "size_all", "all-scroll"]),
    "size_ver": (static(double_arrow(0)), (16, 16),
                 ["ns-resize", "n-resize", "s-resize", "top_side", "bottom_side",
                  "v_double_arrow", "sb_v_double_arrow", "size-ver",
                  "00008160000006810000408080010102"]),
    "size_hor": (static(double_arrow(90)), (16, 16),
                 ["ew-resize", "e-resize", "w-resize", "left_side", "right_side",
                  "h_double_arrow", "sb_h_double_arrow", "size-hor"]),
    "size_fdiag": (static(double_arrow(-45)), (16, 16),
                   ["nwse-resize", "nw-resize", "se-resize", "top_left_corner",
                    "bottom_right_corner", "size-fdiag"]),
    "size_bdiag": (static(double_arrow(45)), (16, 16),
                   ["nesw-resize", "ne-resize", "sw-resize", "top_right_corner",
                    "bottom_left_corner", "size-bdiag"]),
    "col-resize": (static(double_arrow(90, bar=True)), (16, 16), ["split_h"]),
    "row-resize": (static(double_arrow(0, bar=True)), (16, 16), ["split_v"]),
    "up-arrow": (static(simple_arrow(0)), (16, 4), []),
    "right-arrow": (static(simple_arrow(90)), (28, 16), []),
    "down-arrow": (static(simple_arrow(180)), (16, 28), []),
    "left-arrow": (static(simple_arrow(270)), (4, 16), []),
    "wait": ([wait(i) for i in range(FRAMES)], (16, 16), ["watch"]),
    "progress": ([progress(i) for i in range(FRAMES)], (5, 4),
                 ["left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f",
                  "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"]),
}


# ── SVG sources (cursors_scalable) ──────────────────────────────────────────
def write_scalable():
    if SCALABLE.exists():
        shutil.rmtree(SCALABLE)
    SCALABLE.mkdir(parents=True)
    for name, (frames, (hx, hy), aliases) in CURSORS.items():
        target = SCALABLE / name
        target.mkdir()
        meta = []
        for i, content in enumerate(frames):
            filename = f"{name}-{i + 1:02d}.svg" if len(frames) > 1 else f"{name}.svg"
            (target / filename).write_text(content)
            entry = {"filename": filename, "hotspot_x": hx, "hotspot_y": hy,
                     "nominal_size": NOMINAL}
            if len(frames) > 1:
                entry["delay"] = FRAME_DELAY
            meta.append(entry)
        (target / "metadata.json").write_text(json.dumps(meta, indent=4) + "\n")
        for alias in aliases:
            (SCALABLE / alias).symlink_to(name)
    count = sum(1 + len(a) for _, _, a in CURSORS.values())
    print(f"Wrote {len(CURSORS)} cursors ({count} names) to {SCALABLE}")


# ── Xcursor rendering ───────────────────────────────────────────────────────
class Renderer:
    def __init__(self):
        try:
            self.rsvg = ctypes.CDLL("librsvg-2.so.2")
            self.cairo = ctypes.CDLL("libcairo.so.2")
        except OSError as e:
            sys.exit(f"librsvg/cairo not found ({e}) — install librsvg")
        r, c = self.rsvg, self.cairo
        r.rsvg_handle_new_from_file.restype = ctypes.c_void_p
        r.rsvg_handle_new_from_file.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
        r.rsvg_handle_render_cairo.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        c.cairo_image_surface_create.restype = ctypes.c_void_p
        c.cairo_image_surface_create.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int]
        c.cairo_create.restype = ctypes.c_void_p
        c.cairo_create.argtypes = [ctypes.c_void_p]
        c.cairo_scale.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
        c.cairo_surface_flush.argtypes = [ctypes.c_void_p]
        c.cairo_image_surface_get_data.restype = ctypes.c_void_p
        c.cairo_image_surface_get_data.argtypes = [ctypes.c_void_p]
        c.cairo_image_surface_get_stride.argtypes = [ctypes.c_void_p]
        c.cairo_destroy.argtypes = [ctypes.c_void_p]
        c.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
        r.g_object_unref.argtypes = [ctypes.c_void_p]

    def render(self, path, px):
        """Return premultiplied ARGB32 pixels (little-endian), as Xcursor wants."""
        handle = self.rsvg.rsvg_handle_new_from_file(str(path).encode(), None)
        if not handle:
            sys.exit(f"Cannot load {path}")
        surface = self.cairo.cairo_image_surface_create(0, px, px)  # CAIRO_FORMAT_ARGB32
        cr = self.cairo.cairo_create(surface)
        self.cairo.cairo_scale(cr, px / CANVAS, px / CANVAS)
        self.rsvg.rsvg_handle_render_cairo(handle, cr)
        self.cairo.cairo_surface_flush(surface)
        stride = self.cairo.cairo_image_surface_get_stride(surface)
        raw = ctypes.string_at(self.cairo.cairo_image_surface_get_data(surface), stride * px)
        pixels = b"".join(raw[y * stride:y * stride + px * 4] for y in range(px))
        self.cairo.cairo_destroy(cr)
        self.cairo.cairo_surface_destroy(surface)
        self.rsvg.g_object_unref(handle)
        if sys.byteorder != "little":
            pixels = b"".join(pixels[i:i + 4][::-1] for i in range(0, len(pixels), 4))
        return pixels


def write_xcursor(path, images):
    """images: list of (nominal, width, xhot, yhot, delay, pixels)."""
    header = struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(images))
    toc, chunks = b"", b""
    offset = 16 + 12 * len(images)
    for nominal, px, xhot, yhot, delay, pixels in images:
        chunk = struct.pack("<9I", 36, 0xFFFD0002, nominal, 1, px, px, xhot, yhot, delay) + pixels
        toc += struct.pack("<III", 0xFFFD0002, nominal, offset)
        chunks += chunk
        offset += len(chunk)
    path.write_bytes(header + toc + chunks)


def build_xcursor(theme_dir):
    renderer = Renderer()
    out = Path(theme_dir) / "cursors"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    source = Path(theme_dir) / "cursors_scalable"
    if not source.is_dir():
        source = SCALABLE
    aliases = []
    for entry in sorted(source.iterdir()):
        if entry.is_symlink():
            aliases.append((entry.name, entry.resolve().name))
            continue
        meta = json.loads((entry / "metadata.json").read_text())
        images = []
        for size in XCURSOR_SIZES:
            for frame in meta:
                scale = size / frame["nominal_size"]
                px = round(CANVAS * scale)
                images.append((size, px,
                               round(frame["hotspot_x"] * scale),
                               round(frame["hotspot_y"] * scale),
                               frame.get("delay", 0),
                               renderer.render(entry / frame["filename"], px)))
        write_xcursor(out / entry.name, images)
    for alias, target in aliases:
        (out / alias).symlink_to(target)
    print(f"Built Xcursor files in {out}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--xcursor", metavar="THEME_DIR",
                        help="render Xcursor binaries into THEME_DIR/cursors")
    args = parser.parse_args()
    if args.xcursor:
        build_xcursor(args.xcursor)
    else:
        write_scalable()


if __name__ == "__main__":
    main()
