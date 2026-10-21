pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia
import Caelestia.I18n

// Monitor layout control for the Nexus Display page.
//
// Changes are applied live through Hyprland (`hyprctl eval`) and must be kept
// within confirmSeconds or they are reverted. Only a kept change is persisted,
// through hyprmoncfg, so an unconfirmed layout never survives a restart.
Singleton {
    id: root

    readonly property int confirmSeconds: 15
    readonly property string profilesScript: "import json,glob,os;print(json.dumps([json.load(open(f)) for f in sorted(glob.glob(os.path.expanduser('~/.config/hyprmoncfg/profiles/*.json')))]))"

    // Normalised monitors, including disabled ones (see parseMonitors)
    property var monitors: []
    // Saved hyprmoncfg profiles
    property var profiles: []
    // Monitor selected on the Display page
    property string selected

    // A change waiting to be kept or reverted
    property bool pending
    property int countdown
    property var snapshot: []
    // True once a change went through hyprmoncfg (config reload), which writes the new layout
    // to disk straight away; revert then restores the saved snapshot profile
    property bool viaProfile

    readonly property string prevName: "__nexus_prev"
    readonly property string draftName: "__nexus_draft"
    readonly property var userProfiles: profiles.filter(p => !p.name.startsWith("__nexus"))

    readonly property var internalMonitor: monitors.find(m => m.internal) ?? null
    readonly property var externalMonitors: monitors.filter(m => !m.internal && !m.virtual)
    readonly property var selectedMonitor: monitors.find(m => m.name === selected) ?? monitors.find(m => !m.disabled) ?? monitors[0] ?? null
    readonly property bool canChangeLayout: internalMonitor !== null && externalMonitors.length > 0

    // "1920x1080@60.01" for the mode a monitor is running
    function currentMode(m: var): string {
        return `${m.width}x${m.height}@${m.refresh.toFixed(2)}`;
    }

    function parseMonitors(text: string): list<var> {
        let raw;
        try {
            raw = JSON.parse(text);
        } catch (e) {
            return [];
        }
        return raw.map(m => {
            const src = raw.find(o => String(o.id) === String(m.mirrorOf));
            return {
                name: m.name,
                description: m.description ?? "",
                disabled: m.disabled,
                width: m.width,
                height: m.height,
                refresh: m.refreshRate,
                x: m.x,
                y: m.y,
                scale: m.scale,
                transform: m.transform,
                mirrorOf: src ? src.name : "",
                modes: (m.availableModes ?? []).map(s => s.replace(/Hz$/, "")),
                internal: /^(eDP|LVDS|DSI)/.test(m.name),
                virtual: m.name.startsWith("HEADLESS")
            };
        }).map(m => Object.assign(m, {
                mode: currentMode(m)
            }));
    }

    // Size in layout pixels (after scale and rotation)
    function logicalSize(m: var): var {
        const rotated = m.transform % 2 === 1;
        const w = Math.round((rotated ? m.height : m.width) / m.scale);
        const h = Math.round((rotated ? m.width : m.height) / m.scale);
        return {
            w,
            h
        };
    }

    // Width a monitor takes in the layout when running `mode`
    function layoutWidth(m: var, mode: string): int {
        const [w, h] = mode.split("@")[0].split("x").map(Number);
        return logicalSize({
            width: w,
            height: h,
            scale: m.scale,
            transform: m.transform
        }).w;
    }

    function luaFor(m: var): string {
        if (m.disabled)
            return `hl.monitor({ output = "${m.name}", disabled = true })`;
        const parts = [`output = "${m.name}"`, `disabled = false`, `mode = "${m.mode}"`, `position = "${m.x}x${m.y}"`, `scale = ${m.scale}`, `transform = ${m.transform}`];
        if (m.mirrorOf)
            parts.push(`mirror = "${m.mirrorOf}"`);
        return `hl.monitor({ ${parts.join(", ")} })`;
    }

    function run(args: list<string>, done: var): void {
        const proc = cmdComp.createObject(root, {
            command: args,
            done
        });
        proc.running = true;
    }

    function refresh(): void {
        run(["hyprctl", "-j", "monitors", "all"], (code, out) => {
            if (code === 0)
                root.monitors = root.parseMonitors(out);
        });
    }

    function reloadProfiles(): void {
        run(["python3", "-c", profilesScript], (code, out) => {
            try {
                root.profiles = code === 0 ? JSON.parse(out) : [];
            } catch (e) {
                root.profiles = [];
            }
            // The shell restarted while a change was waiting to be kept: offer it again
            if (!root.pending && root.profiles.some(p => p.name === root.prevName)) {
                root.pending = true;
                root.viaProfile = true;
                root.countdown = root.confirmSeconds;
                countdownTimer.restart();
            }
        });
    }

    // Saves the layout before the first change of a confirmation window so it can be restored
    function withSnapshot(then: var): void {
        if (pending) {
            then();
            return;
        }
        snapshot = JSON.parse(JSON.stringify(monitors));
        viaProfile = false;
        pending = true;
        run(["hyprmoncfg", "save", prevName], () => then());
    }

    function fail(title: string, out: string, err: string): void {
        Toaster.toast(title, (err || out).trim().split("\n")[0], "monitor");
    }

    // Applies patches ({ monitorName: { field: value } }) and starts the confirmation countdown.
    // Mirroring cannot be changed on a live output, so those changes go through hyprmoncfg.
    function change(patches: var): bool {
        const next = monitors.map(m => patches[m.name] ? Object.assign({}, m, patches[m.name]) : m);
        if (!next.some(m => !m.disabled)) {
            Toaster.toast(Tr.tr("Display unchanged"), Tr.tr("At least one display has to stay on"), "monitor");
            return false;
        }

        const needsReload = monitors.some(m => patches[m.name] && patches[m.name].mirrorOf !== undefined && patches[m.name].mirrorOf !== m.mirrorOf);
        withSnapshot(() => {
            root.countdown = root.confirmSeconds;
            countdownTimer.restart();

            if (needsReload) {
                root.viaProfile = true;
                root.run(["hyprmoncfg", "save", root.draftName], (code, out, err) => {
                    if (code !== 0)
                        return root.fail(Tr.tr("Could not change the layout"), out, err);
                    root.run(["python3", Quickshell.shellPath("scripts/display-draft.py"), root.draftName, JSON.stringify(patches)], (c2, o2, e2) => {
                        if (c2 !== 0)
                            return root.fail(Tr.tr("Could not change the layout"), o2, e2);
                        root.run(["hyprmoncfg", "apply", root.draftName, "--confirm-timeout", "0"], (c3, o3, e3) => {
                            if (c3 !== 0)
                                root.fail(Tr.tr("Could not change the layout"), o3, e3);
                            refreshTimer.restart();
                        });
                    });
                });
            } else {
                const changed = next.filter(m => patches[m.name]);
                Quickshell.execDetached(["hyprctl", "eval", changed.map(luaFor).join("; ")]);
                refreshTimer.restart();
            }
        });
        return true;
    }

    function setMode(name: string, mode: string): void {
        change({
            [name]: {
                mode
            }
        });
    }

    function setScale(name: string, scale: real): void {
        change({
            [name]: {
                scale
            }
        });
    }

    function setTransform(name: string, transform: int): void {
        change({
            [name]: {
                transform
            }
        });
    }

    function setMirror(name: string, target: string): void {
        const m = monitors.find(o => o.name === name);
        const src = monitors.find(o => o.name === target);
        change({
            [name]: target && src ? {
                mirrorOf: target,
                x: src.x,
                y: src.y
            } : {
                mirrorOf: ""
            }
        });
    }

    function setEnabled(name: string, enabled: bool): void {
        change({
            [name]: {
                disabled: !enabled
            }
        });
    }

    function setPosition(name: string, x: int, y: int): void {
        change({
            [name]: {
                x,
                y
            }
        });
    }

    // Quick layouts: extend, mirror, external-only, laptop-only
    function layout(kind: string): void {
        const internal = internalMonitor;
        if (!internal || externalMonitors.length === 0)
            return;

        const patches = {};
        const preferred = m => m.modes[0] ?? m.mode;

        if (kind === "laptop") {
            patches[internal.name] = {
                disabled: false,
                mirrorOf: "",
                x: 0,
                y: 0
            };
            for (const m of externalMonitors)
                patches[m.name] = {
                    disabled: true
                };
        } else if (kind === "mirror") {
            patches[internal.name] = {
                disabled: false,
                mirrorOf: ""
            };
            for (const m of externalMonitors)
                patches[m.name] = {
                    disabled: false,
                    mode: preferred(m),
                    mirrorOf: internal.name,
                    x: internal.x,
                    y: internal.y
                };
        } else {
            // extend or external-only: lay displays out left to right
            const ordered = kind === "external" ? externalMonitors : [internal, ...externalMonitors];
            let x = 0;
            for (const m of ordered) {
                const patch = {
                    disabled: false,
                    mirrorOf: "",
                    x,
                    y: 0
                };
                if (m !== internal)
                    patch.mode = preferred(m);
                patches[m.name] = patch;
                x += layoutWidth(m, m === internal ? m.mode : preferred(m));
            }
            if (kind === "external")
                patches[internal.name] = {
                    disabled: true
                };
        }
        change(patches);
    }

    // Applies a saved profile through hyprmoncfg, with the current layout kept for revert
    function applyProfile(p: var): void {
        withSnapshot(() => {
            root.viaProfile = true;
            root.countdown = root.confirmSeconds;
            countdownTimer.restart();
            root.run(["hyprmoncfg", "apply", p.name, "--confirm-timeout", "0"], (code, out, err) => {
                if (code !== 0)
                    root.fail(Tr.tr("Could not apply the profile"), out, err);
                refreshTimer.restart();
            });
        });
    }

    function discardTemporaryProfiles(): void {
        run(["hyprmoncfg", "delete", prevName], () => run(["hyprmoncfg", "delete", draftName], () => root.reloadProfiles()));
    }

    function revert(): void {
        countdownTimer.stop();
        if (!pending)
            return;
        pending = false;
        countdown = 0;

        if (viaProfile) {
            run(["hyprmoncfg", "apply", prevName, "--confirm-timeout", "0"], (code, out, err) => {
                if (code !== 0)
                    root.fail(Tr.tr("Could not restore the layout"), out, err);
                root.discardTemporaryProfiles();
                refreshTimer.restart();
            });
        } else {
            const present = new Set(monitors.map(m => m.name));
            Quickshell.execDetached(["hyprctl", "eval", snapshot.filter(m => present.has(m.name)).map(luaFor).join("; ")]);
            discardTemporaryProfiles();
            refreshTimer.restart();
        }
    }

    function autoProfileName(): string {
        return "Auto " + monitors.filter(m => !m.virtual).map(m => m.name).join(" + ");
    }

    // Makes the layout that is live now the one used at startup
    function keep(): void {
        countdownTimer.stop();
        if (!pending)
            return;
        pending = false;
        countdown = 0;

        const name = autoProfileName();
        run(["hyprmoncfg", "save", name], (code, out, err) => {
            if (code !== 0) {
                root.fail(Tr.tr("Could not save the layout"), out, err);
                root.discardTemporaryProfiles();
                return;
            }
            root.run(["hyprmoncfg", "apply", name, "--confirm-timeout", "0"], (c2, o2, e2) => {
                if (c2 !== 0)
                    root.fail(Tr.tr("Could not save the layout"), o2, e2);
                root.discardTemporaryProfiles();
                refreshTimer.restart();
            });
        });
    }

    function saveProfile(name: string): void {
        if (!name.trim())
            return;
        run(["hyprmoncfg", "save", name.trim()], (code, out, err) => {
            if (code === 0)
                Toaster.toast(Tr.tr("Profile saved"), name.trim(), "monitor");
            else
                Toaster.toast(Tr.tr("Could not save the profile"), (err || out).trim().split("\n")[0], "monitor");
            root.reloadProfiles();
        });
    }

    function deleteProfile(name: string): void {
        run(["hyprmoncfg", "delete", name], () => root.reloadProfiles());
    }

    Component.onCompleted: {
        refresh();
        reloadProfiles();
    }

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0)
                root.revert();
        }
    }

    Timer {
        id: refreshTimer

        interval: 600
        onTriggered: root.refresh()
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.includes("mon") || event.name === "configreloaded")
                refreshTimer.restart();
        }

        target: Hyprland
    }

    IpcHandler {
        // Switch layouts from a keybind: qs ipc call displays layout mirror
        function layout(kind: string): string {
            if (!root.canChangeLayout)
                return "no external display";
            if (!["extend", "mirror", "external", "laptop"].includes(kind))
                return "unknown layout, use: extend, mirror, external, laptop";
            root.layout(kind);
            return "ok";
        }

        function mirror(output: string, target: string): void {
            root.setMirror(output, target);
        }

        function enable(output: string, on: bool): void {
            root.setEnabled(output, on);
        }

        function scale(output: string, value: real): void {
            root.setScale(output, value);
        }

        function keep(): void {
            root.keep();
        }

        function revert(): void {
            root.revert();
        }

        function status(): string {
            return JSON.stringify({
                pending: root.pending,
                countdown: root.countdown,
                monitors: root.monitors.map(m => ({
                            name: m.name,
                            mode: m.mode,
                            x: m.x,
                            y: m.y,
                            scale: m.scale,
                            transform: m.transform,
                            disabled: m.disabled,
                            mirrorOf: m.mirrorOf
                        }))
            });
        }

        target: "displays"
    }

    Component {
        id: cmdComp

        Process {
            property var done

            stdout: StdioCollector {
                id: out
            }
            stderr: StdioCollector {
                id: err
            }
            onExited: code => Qt.callLater(() => {
                    if (done)
                        done(code, out.text, err.text);
                    destroy();
                })
        }
    }
}
