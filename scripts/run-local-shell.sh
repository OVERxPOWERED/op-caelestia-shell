#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
ROOT="$(pwd -P)"

# Look for local build or system QML plugin
QML_PREFIX=""
for candidate in \
    "$ROOT/.local-caelestia-plugin/usr/lib/qt6/qml" \
    "$ROOT/.local-caelestia-plugin/usr/local/lib/qt6/qml" \
    "$ROOT/.local-caelestia-plugin/usr/usr/lib/qt6/qml" \
    "/usr/lib/qt6/qml" \
    "/usr/local/lib/qt6/qml"; do
    if [[ -d "$candidate/Caelestia" && -d "$candidate/M3Shapes" ]]; then
        QML_PREFIX="$candidate"
        break
    fi
done

if [[ -n "$QML_PREFIX" ]]; then
    export QML_IMPORT_PATH="$QML_PREFIX${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
    export QML2_IMPORT_PATH="$QML_PREFIX${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
fi

exec quickshell -p "$ROOT/shell.qml" "$@"
