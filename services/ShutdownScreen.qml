pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import Caelestia.Services
import qs.services
import qs.utils

// A minimal "Shutting down" screen that fades in over the desktop before power off, so the
// last thing you see is a finished screen instead of an abrupt cut to a blank display.
// Also used for restart and hibernate. Off until you turn it on in Look & feel > Shutdown, and
// not available on the lock screen.
Singleton {
    id: root

    property bool enabled: false
    property bool active: false

    // How long the fade takes before the power off command runs
    readonly property int fadeMs: 700
    property var pendingCommand: []
    property string label: Tr.tr("Shutting down…")

    function setEnabled(on: bool): void {
        enabled = on;
        stateFile.setText(JSON.stringify({
            enabled: enabled
        }, null, 4));
    }

    // Runs the command after the screen has faded in; returns false if the screen is off.
    // kind is "poweroff", "reboot" or "hibernate"
    function begin(command: list<string>, kind: string): bool {
        if (!enabled || active)
            return false;
        label = kind === "reboot" ? Tr.tr("Restarting…") : kind === "hibernate" ? Tr.tr("Hibernating…") : Tr.tr("Shutting down…");
        pendingCommand = command;
        active = true;
        runTimer.restart();
        return true;
    }

    // Shows the screen for a few seconds without powering off
    function preview(): void {
        if (active)
            return;
        active = true;
        previewTimer.restart();
    }

    // Hibernate leaves the shell running, so clear the screen once the laptop wakes up
    Connections {
        function onResumed(): void {
            root.active = false;
        }

        target: SessionManager
    }

    Timer {
        id: previewTimer

        interval: 3000
        onTriggered: root.active = false
    }

    Timer {
        id: runTimer

        interval: root.fadeMs
        onTriggered: {
            if (!SessionManager.exec(root.pendingCommand))
                Quickshell.execDetached(root.pendingCommand);
        }
    }

    IpcHandler {
        function enable(on: bool): void {
            root.setEnabled(on);
        }

        function preview(): void {
            root.preview();
        }

        function status(): string {
            return JSON.stringify({
                enabled: root.enabled
            });
        }

        target: "shutdownscreen"
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/shutdown-screen.json`
        printErrors: false
        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enabled === true;
            } catch (e) {
                console.warn("[shutdown] could not read shutdown-screen.json:", e);
            }
        }
    }
}
