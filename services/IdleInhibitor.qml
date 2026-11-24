pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    // 0 = off, 1 = prevent sleep (display off/suspend), 2 = also prevent lock
    readonly property int off: 0
    readonly property int preventSleepMode: 1
    readonly property int preventLockAndSleepMode: 2

    property alias mode: props.mode
    readonly property bool active: mode > root.off
    readonly property bool preventSleep: mode >= root.preventSleepMode
    readonly property bool preventLock: mode >= root.preventLockAndSleepMode
    // Only the strongest mode uses the real Wayland idle-inhibitor (it can't
    // selectively allow lock while blocking sleep), so weaker modes fall back
    // to modules/IdleMonitors.qml gating individual idle actions instead
    readonly property bool enabled: mode >= root.preventLockAndSleepMode
    readonly property alias enabledSince: props.enabledSince

    onModeChanged: {
        // Reads props.mode, not the derived `active`: bindings that depend on mode are not
        // re-evaluated before this handler runs, so `active` here is still the previous mode's
        // value and turning a mode on for the first time never stamped a start time
        if (props.mode > root.off)
            props.enabledSince = new Date();
    }

    PersistentProperties {
        id: props

        property int mode: 0
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return root.active;
        }

        function toggle(): void {
            cycle();
        }

        function getMode(): int {
            return props.mode;
        }

        function setMode(newMode: int): void {
            props.mode = Math.max(0, Math.min(2, newMode));
        }

        function cycle(): void {
            props.mode = (props.mode + 1) % 3;
        }

        function enable(): void {
            props.mode = root.preventSleepMode;
        }

        function disable(): void {
            props.mode = root.off;
        }

        target: "idleInhibitor"
    }
}
