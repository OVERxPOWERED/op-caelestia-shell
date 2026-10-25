pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n
import qs.services
import qs.utils

// Background half of Nexus > Doctor. Every few minutes it runs the quick checks in scripts/doctor.py
// at the lowest priority (about a tenth of a second of CPU) and shows a notification when something
// new goes wrong. A problem is reported once; it is reported again only if it changes or comes back.
// Nothing is checked while game mode is on.
Singleton {
    id: root

    property bool enabled: true
    property int minutes: 5

    // check id -> "status|detail" of what the user was last told about
    property var seen: ({})
    property bool baselined

    readonly property string script: Quickshell.shellPath("scripts/doctor.py")
    readonly property bool active: enabled && !GameMode.enabled

    function setEnabled(on: bool): void {
        enabled = on;
        save();
    }

    function setMinutes(m: int): void {
        minutes = m;
        save();
    }

    function save(): void {
        stateFile.setText(JSON.stringify({
            enabled: enabled,
            minutes: minutes,
            baselined: baselined,
            seen: seen
        }, null, 4));
    }

    function check(): void {
        if (!proc.running)
            proc.running = true;
    }

    function handle(results: var): void {
        const next = Object.assign({}, seen);
        let changed = !baselined;
        for (const c of results) {
            if (c.status === "ok" || c.status === "info") {
                if (c.id in next) {
                    delete next[c.id];
                    changed = true;
                }
                continue;
            }
            const fp = `${c.status}|${c.detail}`;
            if (next[c.id] === fp)
                continue;
            next[c.id] = fp;
            changed = true;
            // On the very first run only real breakage is announced; the rest is what you already live with
            if (baselined || c.status === "bad")
                Toaster.toast(Tr.tr("Doctor: %1").arg(c.title), c.detail, "health_and_safety", c.status === "bad" ? Toast.Error : Toast.Warning);
        }
        seen = next;
        baselined = true;
        if (changed)
            save();
    }

    Timer {
        // Let the session settle before the first look
        id: first

        interval: 90000
        running: root.active
        onTriggered: root.check()
    }

    Timer {
        interval: root.minutes * 60000
        running: root.active
        repeat: true
        onTriggered: root.check()
    }

    Process {
        id: proc

        command: ["nice", "-n", "19", "python3", root.script, "check", "--watch"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.handle(JSON.parse(text));
                } catch (e) {
                    console.warn("[doctor-watchdog] could not read the checks:", e);
                }
            }
        }
    }

    IpcHandler {
        function run(): void {
            root.check();
        }

        function enable(on: bool): void {
            root.setEnabled(on);
        }

        function interval(m: int): void {
            root.setMinutes(m);
        }

        function status(): string {
            return JSON.stringify({
                enabled: root.enabled,
                active: root.active,
                minutes: root.minutes,
                baselined: root.baselined,
                seen: root.seen
            });
        }

        target: "doctor"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/doctor-watchdog.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.enabled = d.enabled !== false;
                root.minutes = [2, 5, 15, 30].includes(d.minutes) ? d.minutes : 5;
                root.baselined = d.baselined === true;
                root.seen = d.seen ?? {};
            } catch (e) {
                console.warn("[doctor-watchdog] could not read its state:", e);
            }
        }
    }
}
