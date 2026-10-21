#!/usr/bin/env bash
# Connect to a Wi-Fi network through NetworkManager.
#
# Usage: wifi-connect.sh SSID [BSSID]     (password, if any, in $WIFI_PASSWORD)
#
# Unlike a bare `nmcli device wifi connect`, this reuses the saved profile(s)
# for the SSID and updates their password when one is supplied, so retries do
# not pile up duplicate profiles ("iPhone", "iPhone 1", ...) with stale keys.
#
# Exit codes: 0 connected, 10 password needed, 11 password rejected,
#             12 network not visible, 13 timed out, 1 anything else.
set -uo pipefail

ssid=${1:?usage: wifi-connect.sh SSID [BSSID]}
bssid=${2:-}
password=${WIFI_PASSWORD:-}
unset WIFI_PASSWORD

export LC_ALL=C

# nmcli -t/-g escapes ':' and '\' in values
unescape() { sed -e 's/\\:/:/g' -e 's/\\\\/\\/g'; }

fail() {
    echo "$2" >&2
    exit "$1"
}

visible=$(nmcli -g SSID device wifi list | unescape | grep -Fxc -- "$ssid" || true)
if [[ "$visible" -eq 0 ]]; then
    fail 12 "No network with SSID '$ssid' found"
fi

# Saved profiles for this SSID, most recently used first
profiles=()
while IFS=: read -r uuid ts; do
    profiles+=("$uuid")
done < <(
    while IFS=: read -r uuid type; do
        [[ "$type" == "802-11-wireless" ]] || continue
        p_ssid=$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null | unescape)
        [[ "$p_ssid" == "$ssid" ]] || continue
        ts=$(nmcli -g connection.timestamp connection show uuid "$uuid" 2>/dev/null)
        echo "${ts:-0}:$uuid"
    done < <(nmcli -g UUID,TYPE connection show) | sort -rn | awk -F: '{print $2":"$1}'
)

if [[ -n "$password" ]]; then
    for uuid in "${profiles[@]}"; do
        key_mgmt=$(nmcli -g 802-11-wireless-security.key-mgmt connection show uuid "$uuid")
        args=(802-11-wireless-security.psk "$password" 802-11-wireless-security.psk-flags 0)
        [[ -n "$key_mgmt" ]] || args+=(802-11-wireless-security.key-mgmt wpa-psk)
        nmcli connection modify uuid "$uuid" "${args[@]}" >/dev/null 2>&1 ||
            fail 1 "Could not update the saved password"
    done
fi

if [[ ${#profiles[@]} -gt 0 ]]; then
    cmd=(nmcli --wait 45 connection up uuid "${profiles[0]}")
else
    cmd=(nmcli --wait 45 device wifi connect "$ssid")
    [[ -n "$password" ]] && cmd+=(password "$password")
    [[ -n "$bssid" ]] && cmd+=(bssid "$bssid")
fi

if out=$("${cmd[@]}" 2>&1); then
    echo "$out"
    exit 0
fi

echo "$out" >&2
case "$out" in
*"Secrets were required"* | *"No secrets"* | *"secrets were required"*)
    [[ -n "$password" ]] && exit 11
    exit 10
    ;;
*"No network with SSID"*) exit 12 ;;
*"Timeout"* | *"timed out"*) exit 13 ;;
*) exit 1 ;;
esac
