#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SDDM Network & Tailscale Status Fetcher
# Collects active network connections and Tailscale peer list for the
# Tron Legacy SDDM theme. Writes JSON consumable by QML XMLHttpRequest.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

OUTDIR="/var/cache/sddm"
OUTFILE="$OUTDIR/network-status.json"
mkdir -p "$OUTDIR"
chmod 755 "$OUTDIR"

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    printf '"%s"' "$str"
}

# ── Defaults ──
wlan_name=""
lan_name=""
tailscale_online="false"
tailscale_peers=0
tailscale_machines=""
error_msg=""

# ── Network (NetworkManager) ──
if command -v nmcli &>/dev/null; then
    # Active WiFi connection name
    wlan_name=$(nmcli -t -f NAME,TYPE,DEVICE con show --active 2>/dev/null \
        | awk -F: '$2=="802-11-wireless" {print $1}' | head -1 || true)

    # Active Ethernet connection name
    lan_name=$(nmcli -t -f NAME,TYPE,DEVICE con show --active 2>/dev/null \
        | awk -F: '$2=="802-3-ethernet" {print $1}' | head -1 || true)
else
    error_msg="nmcli not available"
fi

# ── Tailscale ──
if command -v tailscale &>/dev/null; then
    if tailscale status &>/dev/null; then
        tailscale_online="true"
        if command -v jq &>/dev/null; then
            peer_json=$(tailscale status --json 2>/dev/null || echo '{}')
            tailscale_peers=$(echo "$peer_json" | jq -r '[.Peer[]? | select(.Online==true)] | length' 2>/dev/null || echo 0)
            raw_machines=$(echo "$peer_json" | jq -r '[.Peer[]? | select(.Online==true) | .HostName] | join(", ")' 2>/dev/null || echo "")
            if [[ ${#raw_machines} -gt 120 ]]; then
                tailscale_machines="${raw_machines:0:117}…"
            else
                tailscale_machines="$raw_machines"
            fi
        else
            # Basic count without jq
            tailscale_peers=$(tailscale status 2>/dev/null | grep -c '^\S' || true)
            # Subtract 1 to exclude self
            tailscale_peers=$(( tailscale_peers > 0 ? tailscale_peers - 1 : 0 ))
        fi
    else
        tailscale_online="false"
    fi
else
    error_msg="${error_msg}${error_msg:+, }tailscale not available"
fi

# ── Write ──
cat > "$OUTFILE.tmp" <<EOF
{
    "wlan_name": $(json_escape "$wlan_name"),
    "lan_name": $(json_escape "$lan_name"),
    "tailscale_online": $tailscale_online,
    "tailscale_peers": $tailscale_peers,
    "tailscale_machines": $(json_escape "$tailscale_machines"),
    "error": $(json_escape "$error_msg"),
    "timestamp": $(date +%s)
}
EOF

chmod 644 "$OUTFILE.tmp"
mv "$OUTFILE.tmp" "$OUTFILE"
