#!/usr/bin/env bash
set -euo pipefail

touch /tmp/caelestia_boot_lock

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec "$SCRIPT_DIR/run-local-shell.sh" "$@"
