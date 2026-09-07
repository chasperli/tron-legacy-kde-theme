#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Tron Legacy KDE Theme — Installer
# Supports: install, uninstall, dry-run
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Version & Paths ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="0.1.2"

# ── Destinations ──────────────────────────────────────────────────────────────
COLOR_DEST="${HOME:?}/.local/share/color-schemes"
PLASMA_DEST="${HOME}/.local/share/plasma/desktoptheme"
AURORAE_DEST="${HOME}/.local/share/aurorae/themes"
LAF_DEST="${HOME}/.local/share/plasma/look-and-feel"
WALLPAPER_DEST="${HOME}/.local/share/wallpapers"
KONSOLE_DEST="${HOME}/.local/share/konsole"
KATE_DEST="${HOME}/.local/share/org.kde.syntax-highlighting/themes"
VIM_DEST="${HOME}/.vim/colors"
NVIM_DEST="${HOME}/.config/nvim/colors"
VSCODE_DEST="${HOME}/.vscode/extensions/tron-legacy-theme"
PLASMOID_DEST="${HOME}/.local/share/plasma/plasmoids"
SYSTEMD_DEST="${HOME}/.config/systemd/user"
GTK_DEST="${HOME}/.themes"
SDDM_DEST="/usr/share/sddm/themes"

# ── Flags ────────────────────────────────────────────────────────────────────
DRY_RUN=false
UNINSTALL=false
SKIP_SDDM=false
SKIP_EDITORS=false
SKIP_PLASMOID=false
ENABLE_FLATPAK=false

# ── Helpers ──────────────────────────────────────────────────────────────────
ok()     { echo "  [OK] $*"; }
skip()   { echo "  [SKIP] $*"; }
warn()   { echo "  [WARN] $*" >&2; }
fail()   { echo "  [FAIL] $*" >&2; exit 1; }

dry() {
    if $DRY_RUN; then
        echo "  [DRY-RUN] would: $*"
    else
        eval "$*"
    fi
}

# ── Argument Parsing ────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install or uninstall the Tron Legacy KDE Theme.

Options:
  --uninstall      Remove all installed components
  --dry-run        Show what would be done without doing it
  --skip-sddm      Do not install/remove SDDM theme (requires sudo)
  --skip-editors   Do not install/remove editor themes
  --skip-plasmoid  Do not install/remove Container Monitor widget
  --flatpak        Enable Flatpak app overrides + VSCodium theme
  -h, --help       Show this help

Examples:
  ./install.sh                    # Full install
  ./install.sh --dry-run          # Preview changes
  ./install.sh --uninstall        # Remove everything
EOF
}

    while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall)     UNINSTALL=true; shift ;;
        --dry-run)       DRY_RUN=true; shift ;;
        --skip-sddm)     SKIP_SDDM=true; shift ;;
        --skip-editors)  SKIP_EDITORS=true; shift ;;
        --skip-plasmoid) SKIP_PLASMOID=true; shift ;;
        --flatpak)       ENABLE_FLATPAK=true; shift ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if $DRY_RUN && $UNINSTALL; then
    echo "Mode: DRY-RUN UNINSTALL"
elif $DRY_RUN; then
    echo "Mode: DRY-RUN INSTALL"
elif $UNINSTALL; then
    echo "Uninstalling Tron Legacy KDE Theme v${VERSION}..."
else
    echo "Installing Tron Legacy KDE Theme v${VERSION}..."
fi

# ── Sanity Checks ───────────────────────────────────────────────────────────
[[ -d "$SCRIPT_DIR/color-scheme" ]] || fail "Run this script from the repo root."

if ! $UNINSTALL && ! $DRY_RUN; then
    command -v mkdir &>/dev/null || fail "'mkdir' not found."
fi

# ── Backups ─────────────────────────────────────────────────────────────────
backup_dir="${HOME}/.local/share/tron-legacy-backup-$(date +%Y%m%d-%H%M%S)"
maybe_backup() {
    local src="$1"
    if [[ -e "$src" ]] && ! $DRY_RUN && ! $UNINSTALL; then
        mkdir -p "$backup_dir"
        cp -r "$src" "$backup_dir/" && ok "Backed up to $backup_dir/$(basename "$src")"
    fi
}

# ── Flatpak helpers ─────────────────────────────────────────────────────────
setup_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        warn "flatpak not found — skipping Flatpak support"
        return
    fi

    echo ""
    echo "── Flatpak GTK Theme Support ────────────────────────────────────────────"

    # Global user override (covers system + user installed apps)
    if $DRY_RUN; then
        ok "Would set global Flatpak user override: GTK_THEME=TronLegacy + ~/.themes access"
    else
        flatpak override --user --filesystem=~/.themes --env=GTK_THEME=TronLegacy \
            && ok "Global Flatpak override set (GTK_THEME=TronLegacy + ~/.themes)"
    fi

    # VSCodium Flatpak — also install the VS Code theme inside its sandbox
    local vscodium_ext_dir="${HOME}/.var/app/com.vscodium.codium/config/VSCodium/extensions/tron-legacy-theme"
    if flatpak list --app --columns=application 2>/dev/null | grep -qx "com.vscodium.codium"; then
        if [[ -d "$SCRIPT_DIR/vscode/tron-legacy" ]]; then
            dry "mkdir -p '$(dirname "$vscodium_ext_dir")'"
            dry "rm -rf '$vscodium_ext_dir'"
            dry "cp -r '$SCRIPT_DIR/vscode/tron-legacy/.' '$vscodium_ext_dir/'"
            if ! $DRY_RUN; then
                ok "VSCodium Flatpak theme installed"
            else
                ok "Would install VSCodium Flatpak theme"
            fi
        else
            skip "VS Code theme source not found"
        fi
    else
        skip "VSCodium Flatpak not installed"
    fi
}

# ═════════════════════════════════════════════════════════════════════════════
#  UNINSTALL
# ═════════════════════════════════════════════════════════════════════════════
if $UNINSTALL; then
    echo ""
    echo "── Removing KDE / Plasma assets ─────────────────────────────────────────"

    for target in \
        "$COLOR_DEST/TronLegacy.colors" \
        "$PLASMA_DEST/TronLegacy" \
        "$AURORAE_DEST/TronLegacy" \
        "$LAF_DEST/com.tronlegacy.desktop" \
        "$WALLPAPER_DEST/TronLegacy" \
        "$KONSOLE_DEST/TronLegacy.colorscheme" \
        "$GTK_DEST/TronLegacy"; do
        if [[ -e "$target" ]]; then
            dry "rm -rf '$target'" && ok "Removed $target" || true
        fi
    done

    if ! $SKIP_SDDM; then
        echo ""
        echo "── Removing SDDM theme ──────────────────────────────────────────────────"
        if [[ -d "$SDDM_DEST/TronLegacy" ]]; then
            if command -v sudo &>/dev/null; then
                dry "sudo rm -rf '$SDDM_DEST/TronLegacy'" && ok "Removed SDDM theme" || warn "SDDM removal failed"
            else
                warn "sudo not found — remove manually: $SDDM_DEST/TronLegacy"
            fi
        fi
    fi

    if ! $SKIP_EDITORS; then
        echo ""
        echo "── Removing editor themes ───────────────────────────────────────────────"
        for target in \
            "$KATE_DEST/tron-legacy.theme" \
            "$VIM_DEST/tron_legacy.vim" \
            "$NVIM_DEST/tron_legacy.lua" \
            "$VSCODE_DEST" \
            "${HOME}/.var/app/com.vscodium.codium/config/VSCodium/extensions/tron-legacy-theme"; do
            if [[ -e "$target" ]]; then
                dry "rm -rf '$target'" && ok "Removed $target" || true
            fi
        done
    fi

    if ! $SKIP_PLASMOID; then
        echo ""
        echo "── Removing Plasma widget + systemd ─────────────────────────────────────"
        if [[ -d "$PLASMOID_DEST/com.tronlegacy.containermonitor" ]]; then
            dry "rm -rf '$PLASMOID_DEST/com.tronlegacy.containermonitor'" && ok "Removed widget"
        fi
        for unit in tron-containers.service tron-containers.timer; do
            if [[ -f "$SYSTEMD_DEST/$unit" ]]; then
                if ! $DRY_RUN && command -v systemctl &>/dev/null; then
                    systemctl --user disable --now "$unit" 2>/dev/null || true
                fi
                dry "rm -f '$SYSTEMD_DEST/$unit'"
            fi
        done
        if command -v systemctl &>/dev/null && ! $DRY_RUN; then
            systemctl --user daemon-reload 2>/dev/null || true
        fi
    fi

    echo ""
    echo "Uninstall complete. Restart Plasma to see changes:"
    echo "  killall plasmashell && sleep 2 && plasmashell &"
    exit 0
fi

# ═════════════════════════════════════════════════════════════════════════════
#  INSTALL
# ═════════════════════════════════════════════════════════════════════════════

# ── Dependencies ────────────────────────────────────────────────────────────
echo ""
echo "── Checking dependencies ────────────────────────────────────────────────"

MISSING_DEPS=()
if ! command -v rsvg-convert &>/dev/null && ! command -v inkscape &>/dev/null; then
    MISSING_DEPS+=("rsvg-convert (librsvg) or inkscape")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    warn "Missing optional dependencies (wallpaper generation will be skipped):"
    printf >&2 '  - %s\n' "${MISSING_DEPS[@]}"
fi

# ── KDE / Plasma ────────────────────────────────────────────────────────────
echo ""
echo "── KDE / Plasma ─────────────────────────────────────────────────────────"

dry "mkdir -p '$COLOR_DEST' '$PLASMA_DEST' '$AURORAE_DEST' '$LAF_DEST' '$WALLPAPER_DEST' '$KONSOLE_DEST'"

maybe_backup "$COLOR_DEST/TronLegacy.colors"
dry "cp '$SCRIPT_DIR/color-scheme/TronLegacy.colors' '$COLOR_DEST/'" && ok "Color Scheme"

maybe_backup "$PLASMA_DEST/TronLegacy"
dry "rm -rf '$PLASMA_DEST/TronLegacy'"
dry "cp -r '$SCRIPT_DIR/plasma-style/TronLegacy' '$PLASMA_DEST/'" && ok "Plasma Style"

maybe_backup "$AURORAE_DEST/TronLegacy"
dry "rm -rf '$AURORAE_DEST/TronLegacy'"
dry "cp -r '$SCRIPT_DIR/aurorae/TronLegacy' '$AURORAE_DEST/'" && ok "Aurorae Deco"

maybe_backup "$LAF_DEST/com.tronlegacy.desktop"
dry "rm -rf '$LAF_DEST/com.tronlegacy.desktop'"
dry "cp -r '$SCRIPT_DIR/look-and-feel/com.tronlegacy.desktop' '$LAF_DEST/'" && ok "Look & Feel"

maybe_backup "$WALLPAPER_DEST/TronLegacy"
dry "rm -rf '$WALLPAPER_DEST/TronLegacy'"
dry "cp -r '$SCRIPT_DIR/wallpaper/TronLegacy' '$WALLPAPER_DEST/'" && ok "Wallpaper"

maybe_backup "$KONSOLE_DEST/TronLegacy.colorscheme"
dry "cp '$SCRIPT_DIR/konsole/TronLegacy.colorscheme' '$KONSOLE_DEST/'" && ok "Konsole Colors"

# ── GTK Theme ───────────────────────────────────────────────────────────────
echo ""
echo "── GTK Theme ────────────────────────────────────────────────────────────"

dry "mkdir -p '$GTK_DEST'"

maybe_backup "$GTK_DEST/TronLegacy"
dry "rm -rf '$GTK_DEST/TronLegacy'"
dry "cp -r '$SCRIPT_DIR/gtk/TronLegacy' '$GTK_DEST/'" && ok "GTK Theme (3 + 4)"

# ── Flatpak overrides ───────────────────────────────────────────────────────
if $ENABLE_FLATPAK; then
    setup_flatpak
fi

# ── SDDM ────────────────────────────────────────────────────────────────────
if ! $SKIP_SDDM; then
    echo ""
    echo "── SDDM (requires root) ─────────────────────────────────────────────────"
    if command -v sudo &>/dev/null; then
        dry "sudo mkdir -p '$SDDM_DEST'"
        dry "sudo rm -rf '$SDDM_DEST/TronLegacy'"
        dry "sudo cp -r '$SCRIPT_DIR/sddm/TronLegacy' '$SDDM_DEST/'" && ok "SDDM Theme"
        echo ""
        echo "  To test the SDDM theme safely before activating it, run:"
        echo "    sddm-greeter --test-mode --theme '$SDDM_DEST/TronLegacy'"
        echo ""
        echo "  To activate it system-wide, create a config file:"
        echo "    echo '[Theme]' | sudo tee /etc/sddm.conf.d/99-tron-theme.conf"
        echo "    echo 'Current=TronLegacy' | sudo tee -a /etc/sddm.conf.d/99-tron-theme.conf"
    else
        warn "sudo not found — install SDDM theme manually:"
        warn "  sudo cp -r '$SCRIPT_DIR/sddm/TronLegacy' '$SDDM_DEST/'"
    fi
fi

# ── PNG Wallpapers ──────────────────────────────────────────────────────────
echo ""
echo "── PNG Wallpapers ───────────────────────────────────────────────────────"

IMG_SRC_169="$SCRIPT_DIR/wallpaper/TronLegacy/contents/images/1920x1080.svg"
IMG_SRC_32="$SCRIPT_DIR/wallpaper/TronLegacy/contents/images/1920x1280.svg"
IMG_SRC_169_CLU="$SCRIPT_DIR/wallpaper/TronLegacy/contents/images/1920x1080-clu.svg"
IMG_SRC_32_CLU="$SCRIPT_DIR/wallpaper/TronLegacy/contents/images/1920x1280-clu.svg"
PNG_169="$WALLPAPER_DEST/TronLegacy/contents/images/1920x1080.png"
PNG_32="$WALLPAPER_DEST/TronLegacy/contents/images/1920x1280.png"
PNG_169_CLU="$WALLPAPER_DEST/TronLegacy/contents/images/1920x1080-clu.png"
PNG_32_CLU="$WALLPAPER_DEST/TronLegacy/contents/images/1920x1280-clu.png"
REPO_PNG="$WALLPAPER_DEST/TronLegacy/contents/images/repo-preview.png"

if command -v rsvg-convert &>/dev/null; then
    dry "rsvg-convert -w 1920 -h 1080 '$IMG_SRC_169' -o '$PNG_169'" && ok "PNG 1920×1080 (16:9)"
    dry "rsvg-convert -w 1920 -h 1280 '$IMG_SRC_32' -o '$PNG_32'"  && ok "PNG 1920×1280 (3:2)"
    dry "rsvg-convert -w 1920 -h 1080 '$IMG_SRC_169_CLU' -o '$PNG_169_CLU'" && ok "PNG 1920×1080 CLU (16:9)"
    dry "rsvg-convert -w 1920 -h 1280 '$IMG_SRC_32_CLU' -o '$PNG_32_CLU'"  && ok "PNG 1920×1280 CLU (3:2)"
    dry "rsvg-convert -w 1280 -h 853 '$IMG_SRC_32' -o '$REPO_PNG'"  && ok "PNG repo preview"

    if ! $SKIP_SDDM && command -v sudo &>/dev/null && [[ -d "$SDDM_DEST/TronLegacy" ]]; then
        dry "sudo cp '$PNG_32_CLU' '$SDDM_DEST/TronLegacy/tron-legacy-wallpaper.png'" && ok "SDDM background (CLU)"
    fi
elif command -v inkscape &>/dev/null; then
    dry "inkscape --export-type=png --export-width=1920 --export-height=1080 '$IMG_SRC_169' --export-filename='$PNG_169'" && ok "PNG 1920×1080 (16:9)"
    dry "inkscape --export-type=png --export-width=1920 --export-height=1280 '$IMG_SRC_32' --export-filename='$PNG_32'" && ok "PNG 1920×1280 (3:2)"
    dry "inkscape --export-type=png --export-width=1920 --export-height=1080 '$IMG_SRC_169_CLU' --export-filename='$PNG_169_CLU'" && ok "PNG 1920×1080 CLU (16:9)"
    dry "inkscape --export-type=png --export-width=1920 --export-height=1280 '$IMG_SRC_32_CLU' --export-filename='$PNG_32_CLU'" && ok "PNG 1920×1280 CLU (3:2)"

    if ! $SKIP_SDDM && command -v sudo &>/dev/null && [[ -d "$SDDM_DEST/TronLegacy" ]]; then
        dry "sudo cp '$PNG_32_CLU' '$SDDM_DEST/TronLegacy/tron-legacy-wallpaper.png'" && ok "SDDM background (CLU)"
    fi
else
    skip "rsvg-convert and inkscape not found — install librsvg for automatic PNG generation"
fi

# ── Editor themes ───────────────────────────────────────────────────────────
if ! $SKIP_EDITORS; then
    echo ""
    echo "── Editor themes ────────────────────────────────────────────────────────"

    dry "mkdir -p '$KATE_DEST'"
    maybe_backup "$KATE_DEST/tron-legacy.theme"
    dry "cp '$SCRIPT_DIR/kate/tron-legacy.theme' '$KATE_DEST/'" && ok "Kate Theme"

    if command -v vim &>/dev/null || command -v gvim &>/dev/null; then
        dry "mkdir -p '$VIM_DEST'"
        maybe_backup "$VIM_DEST/tron_legacy.vim"
        dry "cp '$SCRIPT_DIR/vim/colors/tron_legacy.vim' '$VIM_DEST/'" && ok "Vim colorscheme"
    else
        skip "Vim not found"
    fi

    if command -v nvim &>/dev/null; then
        dry "mkdir -p '$NVIM_DEST'"
        maybe_backup "$NVIM_DEST/tron_legacy.lua"
        dry "cp '$SCRIPT_DIR/nvim/colors/tron_legacy.lua' '$NVIM_DEST/'" && ok "Neovim colorscheme"
    else
        skip "Neovim not found"
    fi

    if command -v code &>/dev/null || command -v codium &>/dev/null; then
        dry "mkdir -p '$VSCODE_DEST'"
        maybe_backup "$VSCODE_DEST/package.json"
        dry "cp -r '$SCRIPT_DIR/vscode/tron-legacy/.' '$VSCODE_DEST/'" && ok "VS Code theme"
    else
        skip "VS Code / VSCodium not found"
    fi
fi

# ── Plasma Widget + Systemd ─────────────────────────────────────────────────
if ! $SKIP_PLASMOID; then
    echo ""
    echo "── Plasma Widget + Systemd Backend ──────────────────────────────────────"

    dry "mkdir -p '$PLASMOID_DEST'"
    maybe_backup "$PLASMOID_DEST/com.tronlegacy.containermonitor"
    dry "rm -rf '$PLASMOID_DEST/com.tronlegacy.containermonitor'"
    dry "cp -r '$SCRIPT_DIR/plasmoid/tron-container-monitor' '$PLASMOID_DEST/com.tronlegacy.containermonitor'"
    if ! $DRY_RUN; then
        chmod +x "$PLASMOID_DEST/com.tronlegacy.containermonitor/contents/code/fetch.sh"
    fi
    ok "Container Monitor widget"

    dry "mkdir -p '$SYSTEMD_DEST'"
    dry "cp '$SCRIPT_DIR/systemd/tron-containers.service' '$SYSTEMD_DEST/'"
    dry "cp '$SCRIPT_DIR/systemd/tron-containers.timer' '$SYSTEMD_DEST/'"

    if command -v systemctl &>/dev/null && ! $DRY_RUN; then
        systemctl --user daemon-reload
        systemctl --user enable --now tron-containers.timer && ok "Systemd timer enabled & started"
    elif $DRY_RUN; then
        ok "Would enable & start tron-containers.timer"
    else
        warn "systemctl not found — timer not started. Start manually if needed."
    fi

    echo ""
    echo "── First data fetch ─────────────────────────────────────────────────────"
    if ! $DRY_RUN && [[ -x "$PLASMOID_DEST/com.tronlegacy.containermonitor/contents/code/fetch.sh" ]]; then
        if "$PLASMOID_DEST/com.tronlegacy.containermonitor/contents/code/fetch.sh"; then
            ok "First fetch → /tmp/tron-containers.json"
        else
            warn "Fetch failed — is podman installed and running?"
        fi
    elif $DRY_RUN; then
        ok "Would run first fetch"
    fi
fi

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────────────────────"
if $DRY_RUN; then
    echo "Dry-run complete. No files were modified."
fi
echo "Apply the theme via: System Settings → Appearance → Global Theme → Tron Legacy"
echo ""
echo "GTK / Flatpak:"
echo "  Host GTK apps:   gsettings set org.gnome.desktop.interface gtk-theme 'TronLegacy'"
if $ENABLE_FLATPAK; then
    echo "  Flatpak override already applied (GTK_THEME + ~/.themes access)."
    echo "  Restart Flatpak apps to pick up the theme."
else
    echo "  Flatpak support was NOT enabled. Re-run with --flatpak to apply overrides."
fi
echo ""
echo "  Supported Flatpak apps (GTK CSD + native widgets):"
echo "    Flatseal, GNOME Boxes, EasyTAG, Loupe, LibreOffice, Audacity, DBeaver"
echo "  Limited support (Electron / Qt apps only window decorations):"
echo "    Threema, VSCodium, Obsidian, ONLYOFFICE, OpenShot, VLC"
echo ""
if ! $SKIP_PLASMOID; then
    echo "Widget: Right-click Desktop → Add Widgets → Tron Container Monitor"
    echo ""
fi
echo "Editor:"
echo "  Kate:    Settings → Color Theme → Tron Legacy"
echo "  Vim:     :colorscheme tron_legacy"
echo "  Neovim:  vim.cmd.colorscheme('tron_legacy')"
echo "  VS Code: Ctrl+K Ctrl+T → Tron Legacy"
