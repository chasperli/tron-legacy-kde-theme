#!/usr/bin/env python3
"""
Tron Legacy — Icon Theme Generator

Writes the scalable SVG icons of icons/TronLegacy/ from simple path
primitives so every icon shares the same grid, stroke width and glow.

Run from anywhere:  python3 icons/generate-icons.py
Icons not defined here fall back to breeze-dark (see index.theme).

Note: KDE renders icons with QtSvg (SVG Tiny 1.2), which has no filter
support. The neon glow is therefore faked with a wide, translucent stroke
underneath the main stroke instead of feGaussianBlur.
"""

import math
from pathlib import Path

OUT = Path(__file__).resolve().parent / "TronLegacy"

# ── Canonical palette (keep in sync with AGENTS.md) ─────────────────────────
BG = "#050A0E"
CARD = "#0A141E"
CYAN = "#00F5FF"
CYAN_MED = "#0096A8"
CYAN_DIM = "#004858"
TEXT_DIM = "#507080"
ORANGE = "#FF9500"
ORANGE_LT = "#FFB340"
RED = "#FF3030"
GREEN = "#00C8A0"
# CLU palette (login/lock screen, splash) — used for source code
CLU = "#FF5A00"
CLU_CARD = "#1E0A0A"

STROKE = 2.5


# ── Primitives ───────────────────────────────────────────────────────────────
def glow(d, color=CYAN, w=STROKE, fill=CARD):
    """Closed/open shape with a faked neon glow."""
    return (
        f'<path d="{d}" fill="none" stroke="{color}" stroke-opacity=".22" '
        f'stroke-width="{w + 4}" stroke-linejoin="round" stroke-linecap="round"/>'
        f'<path d="{d}" fill="{fill}" stroke="{color}" stroke-width="{w}" '
        f'stroke-linejoin="round" stroke-linecap="round"/>'
    )


def line(d, color=CYAN, w=2, opacity=1, dash=None):
    extra = f' stroke-dasharray="{dash}"' if dash else ""
    return (
        f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" '
        f'stroke-opacity="{opacity}" stroke-linejoin="round" '
        f'stroke-linecap="round"{extra}/>'
    )


def solid(d, color=CYAN):
    return f'<path d="{d}" fill="{color}"/>'


def circle(cx, cy, r, stroke=CYAN, w=2, fill="none", dash=None, opacity=1):
    extra = f' stroke-dasharray="{dash}"' if dash else ""
    return (
        f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" '
        f'stroke-width="{w}" stroke-opacity="{opacity}"{extra}/>'
    )


def dot(cx, cy, r, color=CYAN):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{color}"/>'


def svg(*parts):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" '
        'viewBox="0 0 64 64">' + "".join(parts) + "</svg>\n"
    )


# ── Emblems (centred on 32,41 — the front panel of a folder) ─────────────────
EMBLEMS = {
    "home": line("M23 41 L32 33 L41 41 M26 39 V49 H38 V39 M30 49 V43 H34 V49"),
    "documents": line("M26 33 H35 L39 37 V49 H26 Z M35 33 V37 H39 M29 41 H36 M29 45 H36"),
    "download": line("M32 33 V45 M27 40 L32 45 L37 40 M25 49 H39"),
    "music": line("M29 47 V35 L39 33 V45") + dot(26.5, 47, 2.6) + dot(36.5, 45, 2.6),
    "pictures": line("M24 34 H40 V49 H24 Z M24 46 L30 40 L34 44 L36 42 L40 46") + dot(35.5, 38, 1.8),
    "videos": line("M24 34 H40 V49 H24 Z") + solid("M29.5 37.5 L36 41.5 L29.5 45.5 Z"),
    "desktop": line("M23 34 H41 V45 H23 Z M32 45 V49 M27 49 H37"),
    "templates": line("M26 33 H35 L39 37 V49 H26 Z", dash="3 2.2"),
    "publicshare": line("M28 40 L36 36 M28 42 L36 46")
    + circle(26, 41, 2.6) + circle(38, 35, 2.6) + circle(38, 47, 2.6),
    "remote": circle(32, 41, 8)
    + line("M24 41 H40 M32 33 C27.5 37 27.5 45 32 49 M32 33 C36.5 37 36.5 45 32 49"),
    "manager": line("M26 35 L32 41 L26 47 M33 35 L39 41 L33 47"),
}


# ── Places ───────────────────────────────────────────────────────────────────
FOLDER_BACK = "M6 18 L10 13 H25 L30 18 H54 L58 22 V30 H6 Z"
FOLDER_FRONT = "M6 26 H58 V50 L53 55 H11 L6 50 Z"


def folder(emblem=None):
    parts = [
        glow(FOLDER_BACK, CYAN_MED, 2, BG),
        glow(FOLDER_FRONT),
        line("M12 30 H52", CYAN, 1.2, 0.55),
    ]
    if emblem:
        parts.append(EMBLEMS[emblem])
    return svg(*parts)


def folder_open():
    return svg(
        glow(FOLDER_BACK, CYAN_MED, 2, BG),
        line("M12 22 H50 V28", CYAN_DIM, 1.5),
        glow("M4 30 H60 L55 51 L51 55 H11 L8 51 Z"),
        line("M12 34 H54", CYAN, 1.2, 0.55),
    )


def trash(full=False):
    parts = [
        glow("M20 20 H44 L41 55 H23 Z"),
        glow("M15 15 H49 V20 H15 Z", CYAN, 2, BG),
        line("M27 15 V11 H37 V15", CYAN, 2),
        line("M28 26 L29 49 M32 26 V49 M36 26 L35 49", CYAN_MED, 1.5, 0.8),
    ]
    if full:
        parts.insert(0, line("M24 15 L28 6 M34 15 L40 7 M30 15 L31 8", ORANGE, 2.2))
        parts.append(line("M23 27 H41", ORANGE, 1.5, 0.9))
    return svg(*parts)


# ── Devices ──────────────────────────────────────────────────────────────────
def computer():
    return svg(
        glow("M8 12 H56 V43 L52 46 H12 L8 43 Z"),
        line("M13 17 H51 V40 H13 Z", CYAN_DIM, 1.2),
        line("M17 22 H34", CYAN, 1.5, 0.7),
        line("M27 46 L25 53 H39 L37 46", CYAN_MED, 2),
        line("M18 54 H46", CYAN, 2.5),
    )


def harddisk():
    return svg(
        glow("M8 22 L12 18 H52 L56 22 V44 L52 48 H12 L8 44 Z"),
        line("M12 31 H52", CYAN_DIM, 1.2),
        line("M15 40 H38", CYAN_MED, 2),
        dot(47, 40, 2.6, GREEN),
    )


def usb():
    return svg(
        glow("M25 8 H39 V22 H25 Z", CYAN_MED, 2, BG),
        line("M29 12 V16 M35 12 V16", CYAN_MED, 2),
        glow("M20 22 H44 V52 L40 56 H24 L20 52 Z"),
        line("M26 32 H38", CYAN, 1.5, 0.6),
        dot(32, 46, 2.4, GREEN),
    )


def optical():
    return svg(
        circle(32, 32, 27, CYAN, 6, BG, opacity=0.22),
        circle(32, 32, 27, CYAN, STROKE, CARD),
        circle(32, 32, 19, CYAN_MED, 1.5, dash="22 7"),
        circle(32, 32, 7, CYAN, STROKE),
        dot(32, 32, 2.5),
    )


# ── Apps ─────────────────────────────────────────────────────────────────────
def identity_disc():
    """start-here: the Tron identity disc."""
    return svg(
        circle(32, 32, 28, CYAN, 7, BG, opacity=0.22),
        circle(32, 32, 28, CYAN, STROKE, BG),
        circle(32, 32, 21, CYAN_MED, 2, dash="26.5 6.5"),
        circle(32, 32, 12, CYAN, 7, opacity=0.22),
        circle(32, 32, 12, CYAN, 3.5),
        dot(32, 32, 3.5),
        line("M32 4 V9 M32 55 V60 M4 32 H9 M55 32 H60", CYAN, 2),
    )


def window(*inner):
    return svg(
        glow("M6 14 L10 10 H54 L58 14 V50 L54 54 H10 L6 50 Z"),
        line("M6 19 H58", CYAN_DIM, 1.5),
        dot(51, 14.5, 1.6, CYAN_MED),
        *inner,
    )


def terminal():
    return window(line("M15 29 L23 35 L15 41"), line("M27 42 H39", CYAN, STROKE))


def system_monitor():
    return window(
        line("M12 38 H21 L25 27 L31 47 L35 32 L39 38 H52", ORANGE, 2.2),
        line("M12 46 H52", CYAN_DIM, 1),
    )


def gear():
    pts = []
    teeth = 8
    for i in range(teeth * 4):
        a = math.radians(i * 360 / (teeth * 4) - 90 + 360 / (teeth * 8))
        r = 25 if (i % 4) in (1, 2) else 18.5
        pts.append(f"{32 + r * math.cos(a):.2f} {32 + r * math.sin(a):.2f}")
    d = "M" + " L".join(pts) + " Z"
    return svg(glow(d), circle(32, 32, 8, CYAN, STROKE, BG), dot(32, 32, 2.5))


def text_editor():
    return svg(
        glow("M12 6 H38 L50 18 V58 H12 Z"),
        line("M38 6 V18 H50", CYAN, 2),
        line("M18 26 H40 M18 32 H36 M18 38 H30", CYAN_MED, 2),
        glow("M50 30 L56 36 L38 54 L31 56 L33 49 Z", ORANGE, 2.2, BG),
    )


def browser():
    return svg(
        circle(32, 32, 26, CYAN, 6.5, opacity=0.22),
        circle(32, 32, 26, CYAN, STROKE, CARD),
        line("M6 32 H58 M10 19 H54 M10 45 H54", CYAN_MED, 1.5),
        line("M32 6 C21 14 21 50 32 58 M32 6 C43 14 43 50 32 58", CYAN, 2),
    )


def software_center():
    return svg(
        line("M23 20 V15 A9 9 0 0 1 41 15 V20", CYAN_MED, 2.5),
        glow("M12 20 H52 L49 54 L45 58 H19 L15 54 Z"),
        line("M32 28 V44 M25 37 L32 44 L39 37", GREEN, 2.5),
    )


# ── Mimetypes ────────────────────────────────────────────────────────────────
PAGE = "M13 6 H40 L52 18 V58 H13 Z"


def page(accent, *emblem, edge=CYAN, fill=CARD):
    return svg(
        glow(PAGE, edge, fill=fill),
        line("M40 6 V18 H52", edge, 2),
        *emblem,
        f'<path d="M17 50 H48 V54 H17 Z" fill="{accent}" fill-opacity=".85"/>',
    )


# HUD letters for the file-type labels, drawn as strokes on a 4×6 grid so
# they look the same everywhere (no dependency on installed fonts).
_O = [[(1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0)]]
_P = [[(0, 6), (0, 0), (3, 0), (4, 1), (4, 2), (3, 3), (0, 3)]]
GLYPHS = {
    "A": [[(0, 6), (0, 1), (1, 0), (3, 0), (4, 1), (4, 6)], [(0, 3.5), (4, 3.5)]],
    "B": [[(0, 3), (3, 3), (4, 2), (4, 1), (3, 0), (0, 0), (0, 6), (3, 6), (4, 5), (4, 4), (3, 3)]],
    "C": [[(4, 0), (1, 0), (0, 1), (0, 5), (1, 6), (4, 6)]],
    "D": [[(0, 0), (3, 0), (4, 1), (4, 5), (3, 6), (0, 6), (0, 0)]],
    "E": [[(4, 0), (0, 0), (0, 6), (4, 6)], [(0, 3), (3, 3)]],
    "F": [[(4, 0), (0, 0), (0, 6)], [(0, 3), (3, 3)]],
    "G": [[(4, 0), (1, 0), (0, 1), (0, 5), (1, 6), (3, 6), (4, 5), (4, 3), (2, 3)]],
    "H": [[(0, 0), (0, 6)], [(4, 0), (4, 6)], [(0, 3), (4, 3)]],
    "I": [[(1, 0), (3, 0)], [(2, 0), (2, 6)], [(1, 6), (3, 6)]],
    "J": [[(4, 0), (4, 5), (3, 6), (1, 6), (0, 5)]],
    "K": [[(0, 0), (0, 6)], [(4, 0), (1, 3), (4, 6)], [(0, 3), (1, 3)]],
    "L": [[(0, 0), (0, 6), (4, 6)]],
    "M": [[(0, 6), (0, 0), (2, 3), (4, 0), (4, 6)]],
    "N": [[(0, 6), (0, 0), (4, 6), (4, 0)]],
    "O": _O,
    "P": _P,
    "Q": _O + [[(2.5, 4.5), (4, 6)]],
    "R": _P + [[(2, 3), (4, 6)]],
    "S": [[(4, 0), (1, 0), (0, 1), (0, 2), (1, 3), (3, 3), (4, 4), (4, 5), (3, 6), (0, 6)]],
    "T": [[(0, 0), (4, 0)], [(2, 0), (2, 6)]],
    "U": [[(0, 0), (0, 5), (1, 6), (3, 6), (4, 5), (4, 0)]],
    "V": [[(0, 0), (2, 6), (4, 0)]],
    "W": [[(0, 0), (1, 6), (2, 3), (3, 6), (4, 0)]],
    "X": [[(0, 0), (4, 6)], [(4, 0), (0, 6)]],
    "Y": [[(0, 0), (2, 3), (4, 0)], [(2, 3), (2, 6)]],
    "Z": [[(0, 0), (4, 0), (0, 6), (4, 6)]],
    "2": [[(0, 1), (1, 0), (3, 0), (4, 1), (4, 2), (0, 6), (4, 6)]],
    "3": [[(0, 0), (4, 0), (2, 2.5), (3, 2.5), (4, 3.5), (4, 5), (3, 6), (0, 6)]],
    "4": [[(3, 6), (3, 0), (0, 4), (4, 4)]],
    "7": [[(0, 0), (4, 0), (1.5, 6)]],
    "+": [[(2, 1.5), (2, 4.5)], [(0.5, 3), (3.5, 3)]],
}


def label(rows, color):
    """Write 1–2 rows of up to 4 characters into the middle of the page."""
    unit = 1.75 if max(map(len, rows)) <= 3 else 1.5
    if len(rows) > 1:
        unit = min(unit, 1.35)
    cw, gap, lgap = 4 * unit, 1.6 * unit, 3.2 * unit
    total_h = len(rows) * 6 * unit + (len(rows) - 1) * lgap
    top = (36.5 if len(rows) > 1 else 35) - total_h / 2
    d = []
    for r, text in enumerate(rows):
        x0 = 32.5 - (len(text) * cw + (len(text) - 1) * gap) / 2
        y0 = top + r * (6 * unit + lgap)
        for i, ch in enumerate(text):
            ox = x0 + i * (cw + gap)
            for stroke in GLYPHS[ch]:
                d.append("M" + " L".join(f"{ox + x * unit:.2f} {y0 + y * unit:.2f}"
                                         for x, y in stroke))
    d = " ".join(d)
    return line(d, color, 4.5, 0.18) + line(d, color, 2)


# Small category marks in the top-left corner of a labelled page
MARKS = {
    "doc": line("M18 12 H33 M18 16 H30", CYAN, 1.6, 0.8),
    "sheet": line("M18 11 H34 V20 H18 Z M18 14 H34 M18 17 H34 M23 11 V20 M28.5 11 V20", GREEN, 1.1, 0.9),
    "slides": line("M18 11 H34 V20 H18 Z", ORANGE, 1.4) + solid("M21 18 V15 H23.5 V18 Z M25 18 V13.5 H27.5 V18 Z M29 18 V16 H31.5 V18 Z", ORANGE),
    "pdf": line("M18 12 H33 M18 16 H30", RED, 1.6, 0.8),
    "archive": line("M24 8 V10 M27 10 V12 M24 12 V14 M27 14 V16 M24 16 V18", ORANGE_LT, 2)
    + line("M22.5 18 H28.5 V22 H22.5 Z", ORANGE_LT, 1.4),
    "code": line("M21 11 L18 15 L21 19 M29 11 L32 15 L29 19 M26.5 10.5 L23.5 19.5", CLU, 1.6),
    "config": line("M22 10.5 C19 10.5 21 15 18 15 C21 15 19 19.5 22 19.5 "
                   "M28 10.5 C31 10.5 29 15 32 15 C29 15 31 19.5 28 19.5", GREEN, 1.5),
    "image": line("M18 11 H33 V20 H18 Z M18 18.5 L23 14.5 L26 17 L28 15.5 L33 19", GREEN, 1.3),
    "video": line("M18 11 H33 V20 H18 Z", ORANGE, 1.3) + solid("M23.5 13 L28.5 15.5 L23.5 18 Z", ORANGE),
    "audio": line("M22.5 18.5 V11 L30 9.5 V17", ORANGE_LT, 1.5)
    + dot(21, 18.5, 1.8, ORANGE_LT) + dot(28.5, 17, 1.8, ORANGE_LT),
}
CATEGORY_COLOR = {
    "doc": CYAN, "sheet": GREEN, "slides": ORANGE, "pdf": RED, "archive": ORANGE_LT,
    "code": CLU, "config": GREEN,
    "image": GREEN, "video": ORANGE, "audio": ORANGE_LT,
}


def typed(category, *rows):
    """The shared file icon: page + category mark + file-type label."""
    color = CATEGORY_COLOR[category]
    if category == "code":
        # Source code is a program — drawn entirely in CLU's palette
        return page(color, MARKS[category], label(rows, color), edge=CLU, fill=CLU_CARD)
    return page(color, MARKS[category], label(rows, color))


# Generic icons (no specific format known) keep a large pictogram
MIME = {
    "text": page(CYAN_MED, line("M19 24 H44 M19 30 H40 M19 36 H44 M19 42 H34", CYAN_MED, 2)),
    "document": page(CYAN, line("M19 24 H44 M19 30 H40 M19 36 H44 M19 42 H34", CYAN, 2)),
    "spreadsheet": page(GREEN, line("M19 22 H46 V44 H19 Z M19 29.5 H46 M19 37 H46 M28 22 V44 M37 22 V44",
                                    GREEN, 1.6)),
    "presentation": page(ORANGE, line("M18 22 H47 V42 H18 Z", ORANGE, 2),
                         solid("M23 38 V31 H28 V38 Z M30 38 V27 H35 V38 Z M37 38 V33 H42 V38 Z", ORANGE)),
    "script": page(CLU, line("M19 26 L26 32 L19 38", CLU, STROKE), line("M29 40 H39", CLU, STROKE),
                   edge=CLU, fill=CLU_CARD),
    "image": page(GREEN, line("M19 22 H46 V44 H19 Z M19 41 L28 32 L34 38 L37 35 L46 42"),
                  dot(39, 28, 2.2)),
    "video": page(ORANGE, line("M19 22 H46 V44 H19 Z"), solid("M28 27 L38 33 L28 39 Z", ORANGE)),
    "audio": page(ORANGE_LT, line("M27 40 V24 L41 21 V37", ORANGE_LT),
                  dot(24, 40, 3.2, ORANGE_LT), dot(38, 37, 3.2, ORANGE_LT)),
    "archive": page(ORANGE, line("M30 11 V14.5 M34 14.5 V18 M30 18 V21.5 M34 21.5 V25",
                                 ORANGE, 2.2),
                    glow("M28 28 H36 V38 H28 Z", ORANGE, 2, BG)),
    "executable": page(GREEN, circle(32, 32, 9, GREEN, STROKE),
                       line("M32 19 V23 M32 41 V45 M19 32 H23 M41 32 H45", GREEN, STROKE)),
    "unknown": page(TEXT_DIM, line("M27 27 C27 20 38 20 38 27 C38 32 32 32 32 37", TEXT_DIM, STROKE),
                    dot(32, 43, 1.8, TEXT_DIM)),
}

# Concrete formats: (category, label rows, icon names). Icon names are the
# MIME types with "/" replaced by "-" (shared-mime-info), plus legacy aliases.
TYPED = [
    # Documents
    ("doc", ["DOCX"], ["application-vnd.openxmlformats-officedocument.wordprocessingml.document",
                       "application-vnd.openxmlformats-officedocument.wordprocessingml.template"]),
    ("doc", ["DOC"], ["application-msword", "application-msword-template"]),
    ("doc", ["ODT"], ["application-vnd.oasis.opendocument.text",
                      "application-vnd.oasis.opendocument.text-template"]),
    ("doc", ["RTF"], ["application-rtf", "text-rtf"]),
    ("doc", ["MD"], ["text-markdown", "text-x-markdown"]),
    ("doc", ["TXT"], ["text-plain"]),
    ("doc", ["TEX"], ["text-x-tex"]),
    ("doc", ["LOG"], ["text-x-log"]),
    ("doc", ["EPUB"], ["application-epub+zip"]),
    ("pdf", ["PDF"], ["application-pdf"]),
    # Spreadsheets
    ("sheet", ["XLSX"], ["application-vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                         "application-vnd.openxmlformats-officedocument.spreadsheetml.template"]),
    ("sheet", ["XLS"], ["application-vnd.ms-excel"]),
    ("sheet", ["ODS"], ["application-vnd.oasis.opendocument.spreadsheet",
                        "application-vnd.oasis.opendocument.spreadsheet-template"]),
    ("sheet", ["CSV"], ["text-csv"]),
    # Presentations
    ("slides", ["PPTX"], ["application-vnd.openxmlformats-officedocument.presentationml.presentation",
                          "application-vnd.openxmlformats-officedocument.presentationml.template",
                          "application-vnd.openxmlformats-officedocument.presentationml.slideshow"]),
    ("slides", ["PPT"], ["application-vnd.ms-powerpoint"]),
    ("slides", ["ODP"], ["application-vnd.oasis.opendocument.presentation",
                         "application-vnd.oasis.opendocument.presentation-template"]),
    # Archives & packages
    ("archive", ["ZIP"], ["application-zip"]),
    ("archive", ["TAR"], ["application-x-tar"]),
    ("archive", ["TAR", "GZ"], ["application-x-compressed-tar"]),
    ("archive", ["TAR", "XZ"], ["application-x-xz-compressed-tar"]),
    ("archive", ["TAR", "ZST"], ["application-x-zstd-compressed-tar"]),
    ("archive", ["TAR", "BZ2"], ["application-x-bzip2-compressed-tar",
                                 "application-x-bzip-compressed-tar"]),
    ("archive", ["7Z"], ["application-x-7z-compressed"]),
    ("archive", ["RAR"], ["application-vnd.rar", "application-x-rar"]),
    ("archive", ["GZ"], ["application-gzip", "application-x-gzip"]),
    ("archive", ["XZ"], ["application-x-xz"]),
    ("archive", ["ZST"], ["application-zstd"]),
    ("archive", ["BZ2"], ["application-x-bzip2", "application-x-bzip"]),
    ("archive", ["DEB"], ["application-vnd.debian.binary-package", "application-x-deb"]),
    ("archive", ["RPM"], ["application-x-rpm"]),
    ("archive", ["ISO"], ["application-x-cd-image", "application-vnd.efi.iso"]),
    # Source code (CLU look)
    ("code", ["SH"], ["application-x-shellscript", "text-x-shellscript"]),
    ("code", ["PY"], ["text-x-python", "text-x-python3"]),
    ("code", ["JS"], ["text-javascript", "application-javascript"]),
    ("code", ["C"], ["text-x-csrc"]),
    ("code", ["C++"], ["text-x-c++src"]),
    ("code", ["H"], ["text-x-chdr", "text-x-c++hdr"]),
    ("code", ["QML"], ["text-x-qml"]),
    ("code", ["RS"], ["text-rust"]),
    ("code", ["GO"], ["text-x-go"]),
    ("code", ["JAVA"], ["text-x-java"]),
    ("code", ["CS"], ["text-x-csharp"]),
    ("code", ["LUA"], ["text-x-lua"]),
    ("code", ["PHP"], ["application-x-php"]),
    ("code", ["RB"], ["application-x-ruby"]),
    ("code", ["SQL"], ["application-sql"]),
    # Markup & configuration — configurable, so green
    ("config", ["HTML"], ["text-html"]),
    ("config", ["XML"], ["application-xml", "text-xml"]),
    ("config", ["CSS"], ["text-css"]),
    ("config", ["JSON"], ["application-json"]),
    ("config", ["YAML"], ["application-x-yaml", "text-x-yaml", "application-yaml"]),
    ("config", ["TOML"], ["application-toml", "text-x-toml"]),
    # Media
    ("image", ["PNG"], ["image-png"]),
    ("image", ["JPG"], ["image-jpeg"]),
    ("image", ["SVG"], ["image-svg+xml", "image-svg+xml-compressed"]),
    ("image", ["GIF"], ["image-gif"]),
    ("image", ["WEBP"], ["image-webp"]),
    ("video", ["MP4"], ["video-mp4"]),
    ("video", ["MKV"], ["video-x-matroska"]),
    ("video", ["WEBM"], ["video-webm"]),
    ("audio", ["MP3"], ["audio-mpeg"]),
    ("audio", ["FLAC"], ["audio-flac"]),
    ("audio", ["WAV"], ["audio-x-wav", "audio-wav"]),
    ("audio", ["OGG"], ["audio-x-vorbis+ogg", "audio-ogg"]),
    ("audio", ["OPUS"], ["audio-x-opus+ogg"]),
]


# ── Name map: context → { icon: svg, aliases } ──────────────────────────────
ICONS = {
    "places": [
        (folder(), ["folder", "folder-blue", "folder-cyan"]),
        (folder_open(), ["folder-open", "folder-drag-accept"]),
        (folder("home"), ["user-home", "folder-home", "folder-blue-home"]),
        (folder("documents"), ["folder-documents", "folder-text"]),
        (folder("download"), ["folder-download", "folder-downloads"]),
        (folder("music"), ["folder-music", "folder-sound"]),
        (folder("pictures"), ["folder-pictures", "folder-images", "folder-image"]),
        (folder("videos"), ["folder-videos", "folder-video"]),
        (folder("desktop"), ["user-desktop", "folder-desktop"]),
        (folder("templates"), ["folder-templates"]),
        (folder("publicshare"), ["folder-publicshare", "folder-public"]),
        (folder("remote"), ["folder-remote", "folder-network", "network-workgroup"]),
        (trash(), ["user-trash", "trash-empty"]),
        (trash(full=True), ["user-trash-full", "trash-full"]),
    ],
    "devices": [
        (computer(), ["computer", "computer-laptop", "video-display"]),
        (harddisk(), ["drive-harddisk", "drive-harddisk-root", "drive-harddisk-solidstate"]),
        (usb(), ["drive-removable-media", "drive-removable-media-usb",
                 "drive-removable-media-usb-pendrive", "media-removable"]),
        (optical(), ["media-optical", "drive-optical", "media-optical-cd", "media-optical-dvd"]),
    ],
    "apps": [
        (terminal(), ["utilities-terminal", "org.kde.konsole", "konsole", "terminal",
                      "org.gnome.Terminal", "org.gnome.Console"]),
        (folder("manager"), ["system-file-manager", "org.kde.dolphin", "dolphin",
                             "org.gnome.Nautilus"]),
        (gear(), ["preferences-system", "systemsettings", "preferences-desktop",
                  "org.gnome.Settings"]),
        (text_editor(), ["accessories-text-editor", "org.kde.kate", "kate",
                         "org.kde.kwrite", "kwrite", "org.gnome.TextEditor"]),
        (browser(), ["internet-web-browser", "web-browser", "applications-internet"]),
        (system_monitor(), ["utilities-system-monitor", "org.kde.plasma-systemmonitor",
                            "ksysguard", "org.gnome.SystemMonitor"]),
        (software_center(), ["system-software-install", "org.kde.discover",
                             "plasmadiscover", "org.gnome.Software"]),
        (identity_disc(), ["start-here", "start-here-kde", "start-here-kde-plasma",
                           "distributor-logo"]),
    ],
    "mimetypes": [
        (MIME["text"], ["text-x-generic"]),
        (MIME["document"], ["x-office-document"]),
        (MIME["spreadsheet"], ["x-office-spreadsheet"]),
        (MIME["presentation"], ["x-office-presentation"]),
        (MIME["script"], ["text-x-script", "application-x-executable-script"]),
        (MIME["image"], ["image-x-generic"]),
        (MIME["video"], ["video-x-generic"]),
        (MIME["audio"], ["audio-x-generic"]),
        (MIME["archive"], ["package-x-generic", "application-x-archive"]),
        (MIME["executable"], ["application-x-executable", "application-x-sharedlib"]),
        (MIME["unknown"], ["unknown", "application-octet-stream"]),
        (folder(), ["inode-directory"]),
    ] + [(typed(category, *rows), names) for category, rows, names in TYPED],
}


def main():
    count = 0
    for context, entries in ICONS.items():
        target = OUT / context / "scalable"
        target.mkdir(parents=True, exist_ok=True)
        for old in target.glob("*.svg"):
            old.unlink()
        for content, names in entries:
            for name in names:
                (target / f"{name}.svg").write_text(content)
                count += 1
    print(f"Wrote {count} icons to {OUT}")


if __name__ == "__main__":
    main()
