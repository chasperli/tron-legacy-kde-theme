# Tron Legacy KDE Theme — Release v0.1.6

> A dark, neon-cyan global theme for KDE Plasma 6 inspired by the visual aesthetic of *Tron: Legacy*.

---

## What's New in 0.1.6

- **Icon theme** — Neon-outline SVG icons for places, devices, core apps and common file types. Everything else falls back to Breeze Dark.
- **Cursor theme** — 33 cursors (117 names incl. CSS/X11 aliases) with an animated identity-disc spinner for *busy*/*wait*. Scalable SVG cursors for Plasma 6 Wayland, plus Xcursor files for X11/XWayland rendered during installation.
- **Animated splash** — A spinning identity disc that shifts from CLU orange (login) to grid cyan (desktop) as Plasma loads.
- **Lock screen with screensaver mode** — While idle, only the slowly drifting identity disc and the clock are shown (burn-in protection). Any key or mouse movement brings up the password panel. After 10 seconds without input it fades back to the screensaver.
- **Lock screen fixed for Plasma 6** — Plasma 6 no longer loads lock screens from global themes, so earlier releases silently showed the default Breeze lock screen. It now ships as its own package and `install.sh` selects it automatically.
- **Global theme applies everything** — Color scheme, Plasma style, window decoration, splash, lock screen, icons and cursors are now actually set when you pick *Tron Legacy* in System Settings.

### Removed

- **SDDM status panel** — The network/Tailscale panel on the login screen is gone. A login screen is visible to anyone at the machine and should not reveal network details. `install.sh` cleans up the old root timer and scripts automatically.

## What's Included

- **Global Theme** — Plasma 6 look-and-feel package (desktop, panels, dialogs, tooltips)
- **Window Decorations** — Aurorae theme with glow-accented title bar
- **Splash Screen** — Animated identity disc
- **Lock Screen** — Tron-style lock screen that doubles as a screensaver
- **Icons & Cursors** — Matching neon icon and cursor themes
- **Wallpapers** — SVG-based wallpapers, auto-converted to PNG during installation
- **SDDM Theme** — Login-manager theme
- **GTK 3 / GTK 4** — Theme for GTK and Libadwaita apps, optional Flatpak support (`--flatpak`)
- **Terminal & Editors** — Konsole color scheme, Kate, Vim, Neovim and VS Code themes
- **Widgets** — *Tron Container Monitor* (Podman/Distrobox stats) and *Tron Tailscale Monitor*, both backed by systemd user timers

## Install

```bash
./install.sh            # everything
./install.sh --flatpak  # additionally theme Flatpak GTK apps
./install.sh --help     # all options, incl. --uninstall and --dry-run
```

Then choose **System Settings → Appearance → Global Theme → Tron Legacy**.

Requires: KDE Plasma 6, bash, `rsvg-convert` (librsvg) or Inkscape, sudo (SDDM theme), podman (Container Monitor), tailscale (Tailscale Monitor).

### Upgrading from 0.1.5 or earlier

Simply run `./install.sh` again. It replaces the installed files, selects the new lock screen and removes the old SDDM status timer.

## Disclaimer

This is an independent, fan-made project. It is **not affiliated with, endorsed by, or sponsored by Disney**. TRON™ is a trademark of Disney Enterprises, Inc.

## Full Changelog

See [CHANGELOG.md](CHANGELOG.md).
