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

# Without --rescan no, nmcli starts a new scan whenever its results are older than 30 s
# and waits for it (about 4 s), so asking whether the network exists would delay every
# connection. The cached list is enough; only when the network is missing from it is a
# fresh scan worth waiting for.
is_visible() { nmcli -g SSID device wifi list --rescan "$1" | unescape | grep -Fxq -- "$ssid"; }
if ! is_visible no && ! is_visible yes; then
    fail 12 "No network with SSID '$ssid' found"
fi

# Saved profiles for this SSID, most recently used first
profiles=()
while IFS=$'\t' read -r uuid _ts _key_mgmt p_ssid; do
    [[ "$p_ssid" == "$ssid" ]] && profiles+=("$uuid")
done < <("$(dirname -- "${BASH_SOURCE[0]}")/wifi-profiles.sh" | sort -t$'\t' -k2,2 -rn)

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
