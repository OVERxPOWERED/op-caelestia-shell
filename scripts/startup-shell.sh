#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

case "${1:-}" in
    -k|--kill)
        echo "Stopping OP-Caelestia Shell..."
        killall -9 quickshell 2>/dev/null || true
        exit 0
        ;;
    -r|--restart)
        echo "Restarting OP-Caelestia Shell..."
        killall -9 quickshell 2>/dev/null || true
        sleep 0.5
        shift || true
        ;;
esac

touch /tmp/caelestia_boot_lock
exec "$SCRIPT_DIR/run-local-shell.sh" "$@"
