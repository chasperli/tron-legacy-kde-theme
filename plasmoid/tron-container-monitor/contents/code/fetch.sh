#!/usr/bin/env bash
# Tron Container Monitor — fetch podman stats
# This script is triggered by systemd (tron-containers.timer) or manually.

set -euo pipefail

PODMAN="${PODMAN_BIN:-podman}"
OUTFILE="/tmp/tron-containers.json"
LOGFILE="/tmp/tron-containers.log"

if ! command -v "$PODMAN" &>/dev/null; then
    echo '{"error":"podman not found in PATH"}' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: podman not found in PATH" >> "$LOGFILE"
    exit 1
fi

if ! "$PODMAN" info &>/dev/null; then
    echo '{"error":"podman daemon not reachable"}' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: podman daemon not reachable" >> "$LOGFILE"
    exit 1
fi

COUNT=$("$PODMAN" ps -aq 2>/dev/null | wc -l)
if [[ "$COUNT" -eq 0 ]]; then
    echo '[]' > "$OUTFILE"
    echo "$(date -Iseconds) INFO: no containers found" >> "$LOGFILE"
    exit 0
fi

"$PODMAN" stats --no-stream --format json > "$OUTFILE" 2>>"$LOGFILE" || {
    echo '[]' > "$OUTFILE"
    echo "$(date -Iseconds) ERROR: podman stats failed" >> "$LOGFILE"
    exit 1
}
