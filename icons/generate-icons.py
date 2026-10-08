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
def page(accent, *emblem):
    return svg(
        glow("M13 6 H40 L52 18 V58 H13 Z"),
        line("M40 6 V18 H52", CYAN, 2),
        *emblem,
        f'<path d="M17 50 H48 V54 H17 Z" fill="{accent}" fill-opacity=".85"/>',
    )


MIME = {
    "text": page(CYAN_MED, line("M19 24 H44 M19 30 H40 M19 36 H44 M19 42 H34", CYAN_MED, 2)),
    "script": page(GREEN, line("M19 26 L26 32 L19 38", GREEN, STROKE), line("M29 40 H39")),
    "markup": page(CYAN_MED, line("M24 26 L18 33 L24 40 M41 26 L47 33 L41 40 M35 24 L30 42")),
    "json": page(ORANGE_LT, line("M27 24 C22 24 25 32 20 33 C25 34 22 42 27 42 "
                                 "M38 24 C43 24 40 32 45 33 C40 34 43 42 38 42", ORANGE_LT)),
    "image": page(GREEN, line("M19 22 H46 V44 H19 Z M19 41 L28 32 L34 38 L37 35 L46 42"),
                  dot(39, 28, 2.2)),
    "video": page(ORANGE, line("M19 22 H46 V44 H19 Z"), solid("M28 27 L38 33 L28 39 Z", ORANGE)),
    "audio": page(ORANGE_LT, line("M27 40 V24 L41 21 V37", ORANGE_LT),
                  dot(24, 40, 3.2, ORANGE_LT), dot(38, 37, 3.2, ORANGE_LT)),
    "pdf": page(RED, line("M19 24 H44 M19 30 H44 M19 36 H38", CYAN_MED, 2),
                glow("M33 38 H46 V46 H33 Z", RED, 1.8, BG)),
    "archive": page(ORANGE, line("M30 11 V14.5 M34 14.5 V18 M30 18 V21.5 M34 21.5 V25",
                                 ORANGE, 2.2),
                    glow("M28 28 H36 V38 H28 Z", ORANGE, 2, BG)),
    "executable": page(GREEN, circle(32, 32, 9, GREEN, STROKE),
                       line("M32 19 V23 M32 41 V45 M19 32 H23 M41 32 H45", GREEN, STROKE)),
    "unknown": page(TEXT_DIM, line("M27 27 C27 20 38 20 38 27 C38 32 32 32 32 37", TEXT_DIM, STROKE),
                    dot(32, 43, 1.8, TEXT_DIM)),
}


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
        (MIME["text"], ["text-plain", "text-x-generic", "text-x-log", "text-markdown"]),
        (MIME["script"], ["application-x-shellscript", "text-x-script", "text-x-python",
                          "application-x-executable-script"]),
        (MIME["markup"], ["text-html", "text-xml", "application-xml", "text-x-csrc",
                          "text-x-c++src", "text-x-qml"]),
        (MIME["json"], ["application-json", "text-x-yaml", "application-x-yaml",
                        "application-toml", "text-x-toml"]),
        (MIME["image"], ["image-x-generic", "image-png", "image-jpeg", "image-svg+xml"]),
        (MIME["video"], ["video-x-generic", "video-mp4", "video-x-matroska"]),
        (MIME["audio"], ["audio-x-generic", "audio-mpeg", "audio-flac", "audio-x-wav"]),
        (MIME["pdf"], ["application-pdf"]),
        (MIME["archive"], ["package-x-generic", "application-x-archive", "application-zip",
                           "application-x-tar", "application-x-compressed-tar",
                           "application-x-7z-compressed", "application-x-xz-compressed-tar",
                           "application-x-zstd-compressed-tar"]),
        (MIME["executable"], ["application-x-executable", "application-x-sharedlib"]),
        (MIME["unknown"], ["unknown", "application-octet-stream"]),
        (folder(), ["inode-directory"]),
    ],
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
