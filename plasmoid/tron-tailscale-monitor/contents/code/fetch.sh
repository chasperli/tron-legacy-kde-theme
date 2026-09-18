#!/usr/bin/env bash
# Tron Tailscale Monitor — fetch tailscale status
# Triggered by systemd (tron-tailscale.timer) or manually.

set -euo pipefail

TAILSCALE="${TAILSCALE_BIN:-tailscale}"
OUTFILE="/tmp/tron-tailscale.json"
LOGFILE="/tmp/tron-tailscale.log"

if ! command -v "$TAILSCALE" &>/dev/null; then
    echo '{"error":"tailscale not found in PATH"}' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: tailscale not found in PATH" >> "$LOGFILE"
    exit 1
fi

if ! "$TAILSCALE" status &>/dev/null; then
    echo '{"error":"tailscale not running or not logged in"}' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: tailscale not running or not logged in" >> "$LOGFILE"
    exit 1
fi

"$TAILSCALE" status --json > "$OUTFILE" 2>>"$LOGFILE" || {
    echo '{"error":"tailscale status --json failed"}' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: tailscale status --json failed" >> "$LOGFILE"
    exit 1
}
