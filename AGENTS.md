# Tron Legacy KDE Theme — Agent Guide

## Overview

A comprehensive KDE Plasma 6 global theme inspired by the *Tron: Legacy* visual aesthetic. It provides a dark, neon-cyan-on-black look across the entire desktop stack: window decorations, Plasma widgets, wallpapers, lock/splash screens, SDDM login, and editor color schemes (Kate, Vim, Neovim, VS Code).

The project also includes a custom Plasma 6 widget (`Tron Container Monitor`) that displays live Podman/Distrobox container stats using a systemd user timer backend.

## Project Structure

| Path | Purpose |
|------|---------|
| `color-scheme/TronLegacy.colors` | KDE color scheme palette definition |
| `plasma-style/TronLegacy/` | Plasma desktop theme (SVG widgets, dialogs, panel backgrounds). Includes `opaque/` and `translucent/` variants |
| `aurorae/TronLegacy/` | Window decoration theme (Aurorae engine). SVG buttons + `TronLegacy.rc` config |
| `look-and-feel/com.tronlegacy.desktop/` | Global theme package (`metadata.json`, `contents/defaults`, splash & lockscreen QML) |
| `wallpaper/TronLegacy/` | Wallpaper package with SVG sources in `contents/images/` |
| `sddm/TronLegacy/` | SDDM (login manager) theme |
| `konsole/TronLegacy.colorscheme` | Konsole terminal color scheme |
| `kate/tron-legacy.theme` | Kate/KWrite syntax highlighting theme (JSON) |
| `vim/colors/` | Vim colorscheme (`tron_legacy.vim`) |
| `nvim/colors/` | Neovim Lua colorscheme (`tron_legacy.lua`) |
| `vscode/tron-legacy/` | VS Code theme extension files |
| `plasmoid/tron-container-monitor/` | Plasma 6 applet for monitoring Podman containers |
| `systemd/` | User systemd service & timer for the plasmoid backend |
| `install.sh` | Bash installer that copies assets to the correct KDE paths and enables the systemd timer |

## Tech Stack & Formats

- **KDE Plasma 6** — target platform (`X-Plasma-API-Minimum-Version: 6.0`)
- **QML** (QtQuick 2.15, QtQuick.Layouts 1.15) — splash screen, lock screen, plasmoid UI
- **SVG** — vector assets for Aurorae, Plasma Style, and wallpapers
- **KDE `.colors`** — color scheme INI-style format
- **KDE `.colorscheme`** — Konsole color format
- **JSON** — Kate theme, metadata files
- **Bash** — installer (`install.sh`) and plasmoid data fetcher (`fetch.sh`)
- **systemd** — user unit (`tron-containers.timer` + `.service`)

## Design Language & Conventions

### Color Palette (canonical)

Always keep these colors in sync across all components — the QML files, SVG styles, color schemes, and editor themes must feel identical.

| Role | Hex | RGB | Usage |
|------|-----|-----|-------|
| Deep Background | `#050A0E` | `5,10,14` | Main desktop/bg |
| Card / Panel | `#0A141E` | `10,20,30` | Widget cards, panels |
| Cyan Primary | `#00F5FF` | `0,245,255` | Accents, focus, links, highlights |
| Cyan Medium | `#0096A8` | `0,150,168` | Secondary accents |
| Cyan Dim | `#004858` / `#003848` | — | Borders, subtle separators, bar backgrounds |
| Text Primary | `#80E8F0` / `#B4DCEB` | — | Foreground text |
| Text Dim | `#507080` | — | Inactive/disabled text |
| Orange | `#FF9500` / `#FFB340` | — | Warnings, stats, attention |
| Red | `#FF3030` / `#FF5050` | — | Errors, high usage alerts |
| Green | `#00C8A0` / `#00F5B4` | — | Success, running state |

### Visual Patterns

- **Monospace fonts** for all tech/data UI (plasmoid, splash screen)
- **Letter-spacing** (tracking) for headers/labels to achieve the Tron HUD feel
- **1px borders** with dim cyan (`#004858`) on cards and panels
- **Horizontal glow lines** at the top of active elements (opacity ~0.5–0.8)
- **Corner brackets / frame decorations** for splash/login screens

## Installation & Testing

### Install locally

```bash
./install.sh
```

This script:
1. Copies color scheme, plasma style, aurorae, look-and-feel, wallpaper, konsole scheme into `~/.local/share/…`
2. Installs the SDDM theme to `/usr/share/sddm/themes` (requires `sudo`)
3. Converts SVG wallpapers to PNG using `rsvg-convert` (falls back to `inkscape`)
4. Copies editor themes to Vim/Neovim/VS Code paths
5. Installs the plasmoid and systemd user timer, then starts it

### Requirements

- KDE Plasma 6
- `bash`, `rsvg-convert` (package `librsvg`) or `inkscape`
- `podman` (for the Container Monitor widget)
- `sudo` (for SDDM theme)

### After Install

Apply the theme via: **System Settings → Appearance → Global Theme → Tron Legacy**

Add the widget via: **Right-click Desktop → Add Widgets → Tron Container Monitor**

## Component Reference

### Plasma Style (`plasma-style/`)

- `widgets/background.svg` — general widget background
- `widgets/panel-background.svg` — panel background
- `widgets/tooltip.svg` — tooltip frame
- `dialogs/background.svg` — dialog background
- `opaque/…` — non-transparent variants for opaque panels
- `translucent/…` — semi-transparent variants

### Aurorae (`aurorae/`)

- `decoration.svg` — window frame
- `close.svg`, `maximize.svg`, `minimize.svg`, `restore.svg`, `shade.svg` — window buttons
- `alldesktops.svg`, `keepabove.svg`, `keepbelow.svg`, `menu.svg` — extra buttons
- `TronLegacy.rc` — Aurorae config (button layout, padding, shadows)
- `metadata.json` — theme metadata

### Look and Feel (`look-and-feel/`)

- `contents/defaults` — maps components to theme names (color scheme, plasma style, kwin theme, splash, lock screen)
- `contents/splash/Splash.qml` — animated boot splash with progress stages
- `contents/lockscreen/LockScreen.qml` — lock screen UI

### Container Monitor Plasmoid (`plasmoid/`)

- `metadata.json` — declares `KPackageStructure: Plasma/Applet` and `X-Plasma-API: declarativeappletscript`
- `contents/ui/main.qml` — main QML UI. Reads `/tmp/tron-containers.json` via `XMLHttpRequest`
- `contents/ui/ConfigGeneral.qml` — configuration UI for the widget
- `contents/code/fetch.sh` — fetches `podman stats --no-stream --format json` and writes `/tmp/tron-containers.json`. On error it writes `{"error":"..."}` so the UI can show meaningful feedback.
- `contents/code/mock-containers.json` — synthetic test data. Copy to `/tmp/tron-containers.json` to test the widget without podman.
- `contents/config/config.qml` — config page entry point

**Architecture note:** The widget does **not** execute shell commands directly from QML. Instead:
1. A systemd user timer (`tron-containers.timer`) triggers `fetch.sh` every minute
2. The QML polls `/tmp/tron-containers.json` on a timer
3. On manual refresh, the QML re-reads the file (it does not re-run the script itself)

When packaging or modifying, ensure `fetch.sh` remains executable (`chmod +x`).

## Versioning & Metadata

All KDE-facing packages use `metadata.json` (or `metadata.desktop` for SDDM) with these standard fields:

```json
{
    "KPlugin": {
        "Authors": [{ "Email": "lukas.mathis@ikmail.ch", "Name": "Lukas" }],
        "Description": "…",
        "Id": "com.tronlegacy.desktop",
        "License": "GPL-2.0-or-later",
        "Name": "Tron Legacy",
        "Version": "0.1.2"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
```

Keep `Version` in sync across all `metadata.json` files when releasing.

## Development Workflow

1. **Edit SVGs** — modify assets in `plasma-style/`, `aurorae/`, or `wallpaper/`
2. **Edit QML** — modify `Splash.qml`, `LockScreen.qml`, or `main.qml`
3. **Test** — run `./install.sh` to copy changes into `~/.local/share/…` and reload Plasma (`killall plasmashell && sleep 2 && plasmashell &` or simply log out/in)
4. **For plasmoid UI changes** — after `install.sh`, remove and re-add the widget, or run `killall plasmashell && sleep 2 && plasmashell &`
5. **For systemd timer changes** — after `install.sh`, the script runs `systemctl --user daemon-reload` and restarts the timer

## Important Rules

- **Never break the color palette sync.** If you change a canonical color, update `.colors`, `.colorscheme`, `.theme`, QML `readonly property color` definitions, and SVG styles together.
- **Keep `fetch.sh` simple and safe.** It runs under the user session. Avoid complex parsing — let `podman stats --format json` do the work.
- **SVG-first:** Prefer SVG for all scalable assets. The install script generates PNGs only for wallpapers (KDE/SVG compatibility) and SDDM background.
- **Plasma 6 only:** All QML imports and metadata target Plasma 6. Do not add Plasma 5 compatibility shims.
