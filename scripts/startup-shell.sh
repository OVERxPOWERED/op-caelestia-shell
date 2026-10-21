#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Ask quickshell to exit so it can stop its helper processes (e.g. the
# Bluetooth agent); only force-kill it if it does not exit in time.
stop_shell() {
    killall -TERM quickshell 2>/dev/null || return 0
    for _ in $(seq 30); do
        pgrep -x quickshell >/dev/null || return 0
        sleep 0.1
    done
    killall -9 quickshell 2>/dev/null || true
    sleep 0.5
}

case "${1:-}" in
    -k|--kill)
        echo "Stopping OP-Caelestia Shell..."
        stop_shell
        exit 0
        ;;
    -r|--restart)
        echo "Restarting OP-Caelestia Shell..."
        stop_shell
        shift || true
        ;;
esac

touch /tmp/caelestia_boot_lock
exec "$SCRIPT_DIR/run-local-shell.sh" "$@"
