#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
ROOT="$(pwd -P)"
QML_PREFIX="$ROOT/.local-caelestia-plugin/usr/lib/qt6/qml"

if [[ ! -d "$QML_PREFIX/Caelestia" || ! -d "$QML_PREFIX/M3Shapes" ]]; then
    echo "Missing local Caelestia/M3Shapes QML modules under: $QML_PREFIX" >&2
    echo "Run the local plugin build/install steps again before launching." >&2
    exit 1
fi

export QML_IMPORT_PATH="$QML_PREFIX${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export QML2_IMPORT_PATH="$QML_PREFIX${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

exec quickshell -p "$ROOT/shell.qml" "$@"
