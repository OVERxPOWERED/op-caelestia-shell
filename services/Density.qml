pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services
import qs.utils

// Window spacing (gaps and border) for Look & feel > Density.
//
// Hyprland reads these from ~/.config/hypr/variables.lua at startup. Rather than editing that
// file, the shell pushes the chosen values to Hyprland as live options and again after every
// config reload. "Comfortable" is whatever variables.lua says, so editing that file still works.
// The interface size of the shell is not stored here: it stays per display in Displays.
Singleton {
    id: root

    readonly property var presets: ({
            compact: {
                label: "Compact",
                factor: 0.7
            },
            dense: {
                label: "Dense",
                factor: 0.45
            }
        })

    // From variables.lua; the fallbacks match the values it ships with
    property int baseGapsIn: 7
    property int baseGapsOut: 13
    property int baseBorder: 3

    property string preset: "comfortable"
    property int customGapsIn: baseGapsIn
    property int customGapsOut: baseGapsOut
    property int customBorder: baseBorder

    readonly property int gapsIn: valuesFor(preset).gapsIn
    readonly property int gapsOut: valuesFor(preset).gapsOut
    readonly property int border: valuesFor(preset).border

    function valuesFor(name: string): var {
        if (name === "custom")
            return {
                gapsIn: customGapsIn,
                gapsOut: customGapsOut,
                border: customBorder
            };
        const p = presets[name];
        if (!p)
            return {
                gapsIn: baseGapsIn,
                gapsOut: baseGapsOut,
                border: baseBorder
            };
        return {
            gapsIn: Math.round(baseGapsIn * p.factor),
            gapsOut: Math.round(baseGapsOut * p.factor),
            border: baseBorder >= 2 ? Math.max(2, Math.round(baseBorder * p.factor)) : baseBorder
        };
    }

    function setPreset(name: string): void {
        preset = name;
        save();
        apply();
    }

    // Moving one value turns the current look into a custom one, so the others stay put
    function setValue(key: string, value: int): void {
        const v = valuesFor(preset);
        customGapsIn = v.gapsIn;
        customGapsOut = v.gapsOut;
        customBorder = v.border;
        if (key === "gapsIn")
            customGapsIn = value;
        else if (key === "gapsOut")
            customGapsOut = value;
        else if (key === "border")
            customBorder = value;
        preset = "custom";
        save();
        apply();
    }

    function apply(): void {
        // Game mode zeroes the gaps on purpose; it restores itself through a config reload
        if (GameMode.enabled || !Hypr.usingLua)
            return;
        Hypr.extras.applyOptions({
            "general:gaps_in": gapsIn,
            "general:gaps_out": gapsOut,
            "general:border_size": border
        });
        // Single windows have their own outer gap, set by workspace rules
        const o = gapsOut;
        Hypr.extras.batchMessage([`eval hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = ${o} })`, `eval hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = ${o} })`]);
    }

    function save(): void {
        stateFile.setText(JSON.stringify({
            preset: preset,
            gapsIn: customGapsIn,
            gapsOut: customGapsOut,
            border: customBorder
        }, null, 4));
    }

    Timer {
        id: applyLater

        interval: 400
        onTriggered: root.apply()
    }

    Connections {
        function onConfigReloaded(): void {
            applyLater.restart();
        }

        target: Hypr
    }

    Connections {
        function onEnabledChanged(): void {
            if (!GameMode.enabled)
                applyLater.restart();
        }

        target: GameMode
    }

    IpcHandler {
        function preset(name: string): void {
            root.setPreset(name);
        }

        function set(key: string, value: int): void {
            root.setValue(key, value);
        }

        function status(): string {
            return JSON.stringify({
                preset: root.preset,
                gapsIn: root.gapsIn,
                gapsOut: root.gapsOut,
                border: root.border
            });
        }

        target: "density"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/density.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.customGapsIn = d.gapsIn ?? root.baseGapsIn;
                root.customGapsOut = d.gapsOut ?? root.baseGapsOut;
                root.customBorder = d.border ?? root.baseBorder;
                root.preset = d.preset === "custom" || root.presets[d.preset] ? d.preset : "comfortable";
            } catch (e) {
                console.warn("[density] could not read density.json:", e);
            }
            applyLater.restart();
        }
        onLoadFailed: applyLater.restart()
    }

    FileView {
        path: `${Paths.home}/.config/hypr/variables.lua`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const num = key => {
                const m = text().match(new RegExp(`M\\.${key}\\s*=\\s*(\\d+)`));
                return m ? parseInt(m[1]) : -1;
            };
            const a = num("windowGapsIn"), b = num("windowGapsOut"), c = num("windowBorderSize");
            if (a >= 0)
                root.baseGapsIn = a;
            if (b >= 0)
                root.baseGapsOut = b;
            if (c >= 0)
                root.baseBorder = c;
            applyLater.restart();
        }
    }
}
