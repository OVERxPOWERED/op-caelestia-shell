pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services
import qs.utils

// Look & feel > Motion: one speed for the shell and Hyprland, and an option to give windows
// the same motion curves as the shell. Hyprland's own animation settings are read from
// ~/.config/hypr/hyprland/animations.lua and only changed live, never rewritten.
Singleton {
    id: root

    // Shell and Hyprland speed factor: 1 = as configured, below 1 is faster. The shell half is its
    // own `appearance.anim.durations.scale`, so it stays one setting
    readonly property real speed: GlobalConfig.appearance.anim.durations.scale
    property bool matchShell: false
    property bool touched

    // [{ leaf, enabled, speed, bezier, style }] from animations.lua
    property var base: []

    // Moves that travel get the shell's springy spatial curve, fades the soft effects curve
    readonly property var spatialLeaves: ["windowsIn", "windowsMove", "workspaces", "specialWorkspace"]
    readonly property var effectLeaves: ["windowsOut", "fade", "layers"]

    readonly property bool isDefault: !matchShell && Math.abs(speed - 1) < 0.001

    function setSpeed(factor: real): void {
        GlobalConfig.appearance.anim.durations.scale = factor;
        if (typeof GlobalConfig.save === "function")
            GlobalConfig.save();
        changed();
    }

    function setMatchShell(on: bool): void {
        matchShell = on;
        save();
        changed();
    }

    function changed(): void {
        touched = true;
        applyLater.restart();
    }

    function resetAll(): void {
        matchShell = false;
        save();
        setSpeed(1);
    }

    function points(curve: var): string {
        const p = curve.bezierCurve;
        return `{ ${p[0]}, ${p[1]} }, { ${p[2]}, ${p[3]} }`;
    }

    function apply(): void {
        // Game mode turns animations off on purpose and restores itself through a reload
        if (GameMode.enabled || !Hypr.usingLua || base.length === 0 || (isDefault && !touched))
            return;
        const cmds = [];
        if (matchShell) {
            cmds.push(`eval hl.curve("shellSpatial", { type = "bezier", points = { ${points(Tokens.anim.expressiveDefaultSpatial)} } })`);
            cmds.push(`eval hl.curve("shellEffects", { type = "bezier", points = { ${points(Tokens.anim.expressiveDefaultEffects)} } })`);
        }
        for (const a of base) {
            let bezier = a.bezier;
            let spd = a.speed;
            if (matchShell && spatialLeaves.includes(a.leaf)) {
                bezier = "shellSpatial";
                spd = Tokens.anim.durations.expressiveDefaultSpatial / (GlobalConfig.appearance.anim.durations.scale || 1) / 100;
            } else if (matchShell && effectLeaves.includes(a.leaf)) {
                bezier = "shellEffects";
                spd = Tokens.anim.durations.expressiveSlowEffects / (GlobalConfig.appearance.anim.durations.scale || 1) / 100;
            }
            spd = Math.max(0.5, Math.round(spd * speed * 10) / 10);
            const style = a.style ? `, style = "${a.style}"` : "";
            cmds.push(`eval hl.animation({ leaf = "${a.leaf}", enabled = ${a.enabled}, speed = ${spd}, bezier = "${bezier}"${style} })`);
        }
        Hypr.extras.batchMessage(cmds);
    }

    function save(): void {
        stateFile.setText(JSON.stringify({
            matchShell: matchShell
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
        function speed(factor: real): void {
            root.setSpeed(factor);
        }

        function matchShell(on: bool): void {
            root.setMatchShell(on);
        }

        function reset(): void {
            root.resetAll();
        }

        function status(): string {
            return JSON.stringify({
                speed: root.speed,
                matchShell: root.matchShell,
                leaves: root.base.length
            });
        }

        target: "motion"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/motion.json`
        printErrors: false
        onLoaded: {
            try {
                root.matchShell = JSON.parse(text()).matchShell === true;
            } catch (e) {
                console.warn("[motion] could not read motion.json:", e);
            }
            applyLater.restart();
        }
    }

    FileView {
        path: `${Paths.home}/.config/hypr/hyprland/animations.lua`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const re = /hl\.animation\(\{([^}]*)\}\)/g;
            const field = (s, k) => {
                const m = s.match(new RegExp(`${k}\\s*=\\s*("([^"]*)"|[\\w.]+)`));
                return m ? (m[2] ?? m[1]) : null;
            };
            const list = [];
            let m;
            while ((m = re.exec(text())) !== null) {
                const leaf = field(m[1], "leaf");
                const spd = parseFloat(field(m[1], "speed"));
                if (leaf && !isNaN(spd))
                    list.push({
                        leaf: leaf,
                        enabled: field(m[1], "enabled") !== "false",
                        speed: spd,
                        bezier: field(m[1], "bezier") ?? "default",
                        style: field(m[1], "style")
                    });
            }
            root.base = list;
            applyLater.restart();
        }
    }
}
