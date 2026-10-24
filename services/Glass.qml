pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services
import qs.utils

// Blur and see-through options for Look & feel > Glass. Every option is off (or at the value in
// ~/.config/hypr/variables.lua) until you change it, and everything is pushed to Hyprland live
// and again after each config reload, without touching your config files.
Singleton {
    id: root

    // Windows that are mostly text, kept fully opaque when "Solid text windows" is on
    readonly property string solidClasses: "zen|firefox|chromium|google-chrome|brave-browser|code|code-oss|obsidian|org\\.pwmt\\.zathura|org\\.gnome\\.Evince|libreoffice.*"

    // From variables.lua (a fraction, 0.92 by default)
    property int basePercent: 92

    property bool overviewBlur: false
    property int windowPercent: basePercent
    property bool windowPercentSet: false
    property bool solidText: false

    readonly property int effectivePercent: windowPercentSet ? windowPercent : basePercent
    readonly property bool isDefault: !overviewBlur && !solidText && effectivePercent === basePercent
    property bool touched

    function setOverviewBlur(on: bool): void {
        overviewBlur = on;
        changed();
    }

    function setWindowPercent(p: int): void {
        windowPercent = p;
        windowPercentSet = true;
        changed();
    }

    function setSolidText(on: bool): void {
        solidText = on;
        changed();
    }

    function resetAll(): void {
        overviewBlur = false;
        windowPercentSet = false;
        solidText = false;
        changed();
    }

    function changed(): void {
        touched = true;
        save();
        apply();
    }

    function apply(): void {
        // Game mode turns blur off on purpose and restores itself through a reload
        if (GameMode.enabled || !Hypr.usingLua || (isDefault && !touched))
            return;
        const ns = "caelestia-overview";
        const op = (effectivePercent / 100).toFixed(2);
        const rules = [`eval hl.layer_rule({ match = { namespace = "${ns}" }, blur = ${overviewBlur} })`, `eval hl.layer_rule({ match = { namespace = "${ns}" }, ignore_alpha = 0.2 })`, `eval hl.window_rule({ match = { fullscreen = false }, opacity = "${op} override" })`,
            // Later rules win, so this must come after the general one; off puts them back
            `eval hl.window_rule({ match = { class = "${solidClasses}" }, opacity = "${solidText ? "1.00" : op} override" })`];
        Hypr.extras.batchMessage(rules);
    }

    function save(): void {
        stateFile.setText(JSON.stringify({
            overviewBlur: overviewBlur,
            windowPercent: windowPercentSet ? windowPercent : null,
            solidText: solidText
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
        function blur(on: bool): void {
            root.setOverviewBlur(on);
        }

        function opacity(percent: int): void {
            root.setWindowPercent(percent);
        }

        function solid(on: bool): void {
            root.setSolidText(on);
        }

        function reset(): void {
            root.resetAll();
        }

        function status(): string {
            return JSON.stringify({
                overviewBlur: root.overviewBlur,
                windowPercent: root.effectivePercent,
                solidText: root.solidText,
                isDefault: root.isDefault
            });
        }

        target: "glass"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/glass.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.overviewBlur = d.overviewBlur === true;
                root.solidText = d.solidText === true;
                if (typeof d.windowPercent === "number") {
                    root.windowPercent = d.windowPercent;
                    root.windowPercentSet = true;
                }
            } catch (e) {
                console.warn("[glass] could not read glass.json:", e);
            }
            applyLater.restart();
        }
    }

    FileView {
        path: `${Paths.home}/.config/hypr/variables.lua`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = text().match(/M\.windowOpacity\s*=\s*([0-9.]+)/);
            if (m)
                root.basePercent = Math.round(parseFloat(m[1]) * 100);
            applyLater.restart();
        }
    }
}
