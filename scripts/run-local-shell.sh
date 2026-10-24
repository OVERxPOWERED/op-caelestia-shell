#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
ROOT="$(pwd -P)"

# Look for local build or system QML plugin
QML_PREFIX=""
for candidate in \
    "$ROOT/build/qml" \
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

# Quickshell does not take the icon theme from qt6ct, so without this file pickers, and any
# icon looked up by name, show missing-icon squares. Use the theme you already chose in qt6ct
# (or GTK), unless QS_ICON_THEME is set.
if [[ -z "${QS_ICON_THEME:-}" ]]; then
    theme="$(sed -n 's/^icon_theme=//p' "${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf" 2>/dev/null | head -n1)"
    [[ -n "$theme" ]] || theme="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
    [[ -n "$theme" ]] && export QS_ICON_THEME="$theme"
fi

exec quickshell -p "$ROOT/shell.qml" "$@"
