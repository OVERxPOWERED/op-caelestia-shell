#!/usr/bin/env bash
# List the saved Wi-Fi profiles, one per line: UUID <TAB> TIMESTAMP <TAB> KEY-MGMT <TAB> SSID
#
# nmcli cannot show the SSID of every profile in one call, so each profile is asked
# separately. Done one after the other that costs ~40 ms per profile (2.5 s for 59
# profiles); running the calls side by side brings the whole listing under half a second.
#
# TIMESTAMP is when the profile was last used (0 if never); KEY-MGMT is empty for open networks.
set -uo pipefail
export LC_ALL=C

# nmcli -g escapes ':' and '\' in values
unescape() { sed -e 's/\\:/:/g' -e 's/\\\\/\\/g'; }

one() {
    local uuid=$1 ts=$2 ssid key_mgmt
    { IFS= read -r ssid; IFS= read -r key_mgmt; } < <(
        nmcli -g 802-11-wireless.ssid,802-11-wireless-security.key-mgmt connection show uuid "$uuid" 2>/dev/null
    )
    [[ -n "$ssid" ]] || return 0
    ssid=$(printf '%s' "$ssid" | unescape)
    printf '%s\t%s\t%s\t%s\n' "$uuid" "${ts:-0}" "$key_mgmt" "$ssid"
}
export -f one unescape

nmcli -t -f UUID,TYPE,TIMESTAMP connection show 2>/dev/null |
    awk -F: '$2 == "802-11-wireless" { print $1, $3 }' |
    xargs -P 8 -n 2 bash -c 'one "$@"' _
