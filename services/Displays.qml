pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia
import Caelestia.Config
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
    // What the pending change does, for the confirmation dialog
    property string pendingSummary
    // True once a change went through hyprmoncfg (config reload), which writes the new layout
    // to disk straight away; revert then restores the saved snapshot profile
    property bool viaProfile

    readonly property string prevName: "__nexus_prev"
    readonly property string draftName: "__nexus_draft"
    readonly property var userProfiles: profiles.filter(p => !p.name.startsWith("__nexus"))

    // Include virtual outputs (e.g. Sunshine's) when picking displays for layouts; for testing
    property bool treatVirtualAsExternal
    // Set while the plug-in chooser is open: { name, description }
    property var chooser: null
    // A saved layout waiting for a yes or no before it is applied
    property var profileToApply: null
    readonly property double startedAt: Date.now()

    readonly property var internalMonitor: monitors.find(m => m.internal) ?? null
    readonly property var externalMonitors: monitors.filter(m => !m.internal && (treatVirtualAsExternal || !m.virtual))
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
                // Hyprland adds a placeholder output named FALLBACK when no real display is left
                fallback: m.name === "FALLBACK",
                virtual: m.name.startsWith("HEADLESS") || m.name === "FALLBACK"
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

    // A mirror is not re-rendered for the second screen, so Hyprland squeezes or stretches the
    // picture when the two shapes differ (16:9 on a 4:3 or 16:10 screen). Pick the mode of the
    // mirrored display whose shape matches the source best, highest resolution first.
    function bestMirrorMode(ext: var, src: var): var {
        const size = logicalSize(src);
        const target = size.w / size.h;
        const parsed = (ext.modes ?? []).map(m => {
            const [res, rate] = m.split("@");
            const [w, h] = res.split("x").map(Number);
            return {
                mode: m,
                pixels: w * h,
                rate: parseFloat(rate),
                diff: Math.abs(w / h - target)
            };
        });
        if (parsed.length === 0)
            return {
                mode: ext.mode,
                exact: false
            };
        const closest = Math.min(...parsed.map(p => p.diff));
        const pool = parsed.filter(p => p.diff <= closest + 0.01);
        pool.sort((a, b) => b.pixels - a.pixels || Math.abs(a.rate - 60) - Math.abs(b.rate - 60));
        return {
            mode: pool[0].mode,
            exact: closest < 0.02
        };
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

    // Last scale and rotation seen for each display while it was on, so a display that has to be
    // switched back on (see handleRemoved) returns the way it was
    property var lastGood: ({})

    function refresh(done: var): void {
        run(["hyprctl", "-j", "monitors", "all"], (code, out) => {
            if (code === 0) {
                root.monitors = root.parseMonitors(out);
                for (const m of root.monitors) {
                    if (!m.disabled && !m.fallback)
                        root.lastGood[m.name] = {
                            scale: m.scale,
                            transform: m.transform
                        };
                }
            }
            if (done)
                done();
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

    // One line per changed display, e.g. "HDMI-A-1: 125%, mirrors eDP-1"
    function describe(patches: var): string {
        const rotations = [Tr.tr("normal"), Tr.tr("rotated 90°"), Tr.tr("rotated 180°"), Tr.tr("rotated 270°")];
        return Object.keys(patches).map(name => {
            const p = patches[name];
            const parts = [];
            if (p.disabled !== undefined)
                parts.push(p.disabled ? Tr.tr("turned off") : Tr.tr("on"));
            if (p.mode)
                parts.push(p.mode.replace("@", " @ ") + " Hz");
            if (p.scale !== undefined)
                parts.push(`${Math.round(p.scale * 100)}%`);
            if (p.transform !== undefined)
                parts.push(rotations[p.transform] ?? "");
            if (p.mirrorOf !== undefined)
                parts.push(p.mirrorOf ? Tr.tr("mirrors %1").arg(p.mirrorOf) : Tr.tr("no longer mirrored"));
            if ((p.x !== undefined || p.y !== undefined) && p.mirrorOf === undefined)
                parts.push(Tr.tr("moved"));
            return `${name}: ${parts.filter(x => x).join(", ")}`;
        }).join("\n");
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
    function change(patches: var, note = ""): bool {
        if (pending)
            return applyChange(patches, note);

        // The first change of a confirmation window starts from the displays as they are right now,
        // not from a copy that may predate something done outside the shell
        refresh(() => root.applyChange(patches, note));
        return true;
    }

    function applyChange(patches: var, note = ""): bool {
        const next = monitors.map(m => patches[m.name] ? Object.assign({}, m, patches[m.name]) : m);
        if (!next.some(m => !m.disabled)) {
            Toaster.toast(Tr.tr("Display unchanged"), Tr.tr("At least one display has to stay on"), "monitor");
            return false;
        }

        pendingSummary = describe(patches) + (note ? `\n${note}` : "");
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
        if (!target || !src || !m) {
            change({
                [name]: {
                    mirrorOf: ""
                }
            });
            return;
        }
        const best = bestMirrorMode(m, src);
        change({
            [name]: {
                mirrorOf: target,
                mode: best.mode,
                x: src.x,
                y: src.y
            }
        }, best.exact ? "" : mismatchNote);
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
        let note = "";
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
            for (const m of externalMonitors) {
                const best = bestMirrorMode(m, internal);
                if (!best.exact)
                    note = mismatchNote;
                patches[m.name] = {
                    disabled: false,
                    mode: best.mode,
                    mirrorOf: internal.name,
                    x: internal.x,
                    y: internal.y
                };
            }
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
        change(patches, note);
    }

    // Applies a saved profile through hyprmoncfg, with the current layout kept for revert
    function applyProfile(p: var): void {
        pendingSummary = Tr.tr("Profile: %1").arg(p.name);
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

    // Clicking a saved layout asks first; applying it still goes through Keep/Revert afterwards
    function askApplyProfile(p: var): void {
        profileToApply = p;
    }

    function answerProfile(yes: bool): void {
        const p = profileToApply;
        profileToApply = null;
        if (yes && p)
            applyProfile(p);
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

    // ---- interface size (per display) ------------------------------------------------------

    // The shell's text and spacing on one display, set in that display's own config file, so a
    // projector or a big monitor can differ from the laptop panel
    function interfaceSize(name: string): real {
        return GlobalConfig.forScreen(name).appearance.font.scale;
    }

    function setInterfaceSize(name: string, size: real): void {
        const c = GlobalConfig.forScreen(name);
        c.appearance.font.scale = size;
        c.appearance.padding.scale = size;
        c.appearance.spacing.scale = size;
        c.save();
    }

    // ---- plug and unplug -------------------------------------------------------------------

    readonly property string mismatchNote: Tr.tr("No mode matches the laptop's shape, so the picture may look stretched.")

    property var addedQueue: []

    // A display you can actually look at (not Hyprland's FALLBACK, and not a virtual output
    // unless virtual ones are being treated as real for testing)
    function isPhysical(m: var): bool {
        return !m.fallback && (treatVirtualAsExternal || !m.virtual);
    }

    function isExternalName(name: string): bool {
        return !/^(eDP|LVDS|DSI)/.test(name) && (treatVirtualAsExternal || !name.startsWith("HEADLESS"));
    }

    function displayKey(m: var): string {
        return m.description || m.name;
    }

    // The saved layout made for exactly the displays that are connected now, if there is one
    function profileForConnected(): var {
        const real = monitors.filter(m => treatVirtualAsExternal || !m.virtual);
        const connected = new Set(real.map(displayKey));
        const matches = userProfiles.filter(p => {
            const keys = new Set(p.outputs.filter(o => treatVirtualAsExternal || !o.name.startsWith("HEADLESS")).map(o => o.description || o.name));
            return keys.size === connected.size && [...keys].every(k => connected.has(k));
        });
        matches.sort((a, b) => String(b.updated_at).localeCompare(String(a.updated_at)));
        return matches[0] ?? null;
    }

    // A display appeared: apply the layout saved for this set of displays, or ask what to do
    function handleAdded(name: string): void {
        if (pending || chooser)
            return;
        const m = monitors.find(o => o.name === name);
        if (!m || !isExternalName(name))
            return;

        const known = profileForConnected();
        if (known) {
            run(["hyprmoncfg", "apply", known.name, "--confirm-timeout", "0"], (code, out, err) => {
                if (code === 0)
                    Toaster.toast(Tr.tr("Display layout applied"), Tr.tr("Using your saved layout \"%1\"").arg(known.name), "monitor");
                else
                    root.fail(Tr.tr("Could not apply the saved layout"), out, err);
                refreshTimer.restart();
            });
        } else {
            openChooser(m);
        }
    }

    function openChooser(m: var): void {
        chooser = {
            name: m.name,
            description: m.description || m.name
        };
        chooserTimer.restart();
    }

    function dismissChooser(): void {
        chooserTimer.stop();
        chooser = null;
    }

    function chooseLayout(kind: string): void {
        dismissChooser();
        layout(kind);
    }

    // A display went away. If that leaves nothing on (e.g. "external only" and the cable was
    // pulled), turn the laptop panel back on so the screen is never left black.
    function handleRemoved(name: string): void {
        if (chooser && chooser.name === name)
            dismissChooser();
        if (monitors.some(m => !m.disabled && isPhysical(m)))
            return;

        if (pending)
            revert();
        const internal = internalMonitor;
        if (internal && !monitors.some(m => !m.disabled && isPhysical(m))) {
            const was = lastGood[internal.name] ?? {
                scale: 1,
                transform: 0
            };
            Quickshell.execDetached(["hyprctl", "eval", `hl.monitor({ output = "${internal.name}", disabled = false, mode = "preferred", position = "0x0", scale = ${was.scale}, transform = ${was.transform} })`]);
            Toaster.toast(Tr.tr("Laptop screen turned back on"), Tr.tr("The display you were using was disconnected"), "laptop");
            refreshTimer.restart();
        }
    }

    Timer {
        id: addedTimer

        // Give Hyprland a moment to publish the new display's modes before looking at it
        interval: 900
        onTriggered: {
            const names = root.addedQueue;
            root.addedQueue = [];
            root.refresh(() => {
                root.reloadProfiles();
                // profiles load asynchronously; wait for them before matching
                matchTimer.names = names;
                matchTimer.start();
            });
        }
    }

    Timer {
        id: matchTimer

        property var names: []

        interval: 350
        onTriggered: names.forEach(n => root.handleAdded(n))
    }

    Timer {
        id: removedTimer

        property string name

        interval: 700
        onTriggered: root.refresh(() => root.handleRemoved(name))
    }

    Timer {
        id: chooserTimer

        interval: 45000
        onTriggered: root.dismissChooser()
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

            if (event.name === "monitoraddedv2") {
                // Displays already connected when the shell starts are not "new"
                const [, name] = event.parse(3);
                if (Date.now() - root.startedAt > 10000 && root.isExternalName(name)) {
                    root.addedQueue = [...root.addedQueue, name];
                    addedTimer.restart();
                }
            } else if (event.name === "monitorremovedv2") {
                const [, name] = event.parse(3);
                removedTimer.name = name;
                removedTimer.restart();
            }
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

        function rotate(output: string, transform: int): void {
            root.setTransform(output, transform);
        }

        // Open the "what should this display do" chooser by hand
        function chooser(): string {
            if (!root.canChangeLayout)
                return "no external display";
            root.openChooser(root.externalMonitors[0]);
            return "ok";
        }

        function askProfile(name: string): string {
            const p = root.userProfiles.find(x => x.name === name);
            if (!p)
                return "no such profile";
            root.askApplyProfile(p);
            return "ok";
        }

        function answerProfile(yes: bool): void {
            root.answerProfile(yes);
        }

        function choose(kind: string): void {
            root.chooseLayout(kind);
        }

        function includeVirtual(on: bool): void {
            root.treatVirtualAsExternal = on;
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
                chooser: root.chooser,
                profileToApply: root.profileToApply ? root.profileToApply.name : null,
                profiles: root.userProfiles.map(p => p.name),
                screens: Quickshell.screens.map(s => ({
                            name: s.name,
                            width: s.width,
                            height: s.height,
                            scale: s.devicePixelRatio
                        })),
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
