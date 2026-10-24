pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

// Default fonts for apps (Look & feel > App fonts). The work is done by scripts/app-fonts.py,
// which owns one fontconfig file; apps pick the change up the next time they start.
Singleton {
    id: root

    property bool enabled
    property string sans: "Adwaita Sans"
    property string mono: "JetBrains Mono"
    property var sansChoices: []
    property var monoChoices: []
    property string nowSans
    property string nowMono
    property bool busy
    property var added: []
    property string message

    // Also give the shell's own text these fonts (its icon font is never touched)
    property bool shellToo
    property var shellOriginal: null

    // Qt reads the installed fonts once, when the shell starts, so a font added since then is
    // unknown to it (text falls back to another font) until the shell restarts
    readonly property bool needsRestart: {
        added.length; // re-check when the list of added fonts changes
        const known = Qt.fontFamilies();
        return enabled && (!known.includes(sans) || !known.includes(mono));
    }

    function restartShell(): void {
        Quickshell.execDetached(["setsid", "-f", "sh", "-c", `sleep 0.5; exec "${Quickshell.shellPath("scripts/startup-shell.sh")}" -r`]);
    }

    readonly property string script: Quickshell.shellPath("scripts/app-fonts.py")

    function refresh(): void {
        statusProc.running = true;
    }

    function turn(on: bool): void {
        run(on ? ["set", sans, mono] : ["off"]);
    }

    function choose(newSans: string, newMono: string): void {
        sans = newSans;
        mono = newMono;
        if (enabled)
            run(["set", sans, mono]);
        applyShell();
    }

    function addFont(path: string): void {
        run(["add", path]);
    }

    function removeFont(file: string): void {
        // A font that is in use falls back to the built-in choice before it disappears
        const family = added.find(a => a.file === file)?.family;
        const newSans = family === sans ? "Adwaita Sans" : sans;
        const newMono = family === mono ? "JetBrains Mono" : mono;
        if (enabled && (newSans !== sans || newMono !== mono))
            choose(newSans, newMono);
        run(["remove", file]);
    }

    function setShellToo(on: bool): void {
        shellToo = on;
        saveState();
        applyShell();
    }

    // The shell's text styles share one family each; put them back exactly as they were when off
    function applyShell(): void {
        const f = GlobalConfig.appearance.font;
        const styles = ["headline", "title", "body", "label"];
        if (enabled && shellToo) {
            if (!shellOriginal) {
                shellOriginal = {
                    headline: f.headline.family,
                    title: f.title.family,
                    body: f.body.family,
                    label: f.label.family,
                    mono: f.mono.family
                };
                saveState();
            }
            for (const s of styles)
                f[s].family = sans;
            f.mono.family = mono;
        } else if (shellOriginal) {
            for (const s of styles.concat(["mono"]))
                f[s].family = shellOriginal[s];
            shellOriginal = null;
            saveState();
        } else {
            return;
        }
        if (typeof GlobalConfig.save === "function")
            GlobalConfig.save();
    }

    function saveState(): void {
        stateFile.setText(JSON.stringify({
            shellToo: shellToo,
            shellOriginal: shellOriginal
        }, null, 4));
    }

    // One script call at a time; later ones wait their turn
    property var queue: []

    function run(args: var): void {
        queue = queue.concat([args]);
        if (!busy)
            next();
    }

    function next(): void {
        if (queue.length === 0)
            return;
        busy = true;
        setProc.command = ["python3", script].concat(queue[0]);
        queue = queue.slice(1);
        setProc.running = true;
    }

    Component.onCompleted: refresh()

    FileView {
        id: stateFile

        path: `${Paths.state}/app-fonts.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.shellToo = d.shellToo === true;
                root.shellOriginal = d.shellOriginal ?? null;
            } catch (e) {
                console.warn("[app-fonts] could not read app-fonts.json:", e);
            }
        }
    }

    Process {
        id: statusProc

        command: ["python3", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.enabled = d.enabled;
                    root.sansChoices = d.sansChoices;
                    root.monoChoices = d.monoChoices;
                    root.nowSans = d.nowSans;
                    root.nowMono = d.nowMono;
                    root.added = d.added;
                    if (d.sans)
                        root.sans = d.sans;
                    if (d.mono)
                        root.mono = d.mono;
                    root.applyShell();
                } catch (e) {
                    console.warn("[app-fonts] status failed:", e);
                }
            }
        }
    }

    Process {
        id: setProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    root.message = JSON.parse(text).message ?? "";
                } catch (e) {
                    root.message = "";
                }
                if (root.queue.length > 0)
                    root.next();
                else
                    root.refresh();
            }
        }
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify({
                enabled: root.enabled,
                sans: root.sans,
                mono: root.mono,
                nowSans: root.nowSans,
                nowMono: root.nowMono
            });
        }

        function turn(on: bool): void {
            root.turn(on);
        }

        function choose(newSans: string, newMono: string): void {
            root.choose(newSans, newMono);
        }

        function shell(on: bool): void {
            root.setShellToo(on);
        }

        function shellFamily(): string {
            return GlobalConfig.appearance.font.body.family + " / " + GlobalConfig.appearance.font.mono.family;
        }

        target: "appfonts"
    }
}
