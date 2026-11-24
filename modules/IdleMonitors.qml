pragma ComponentBehavior: Bound

import "lock"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock") {
            if (!IdleInhibitor.preventLock)
                lock.lock.locked = true;
        } else if (action === "unlock") {
            lock.lock.locked = false;
        } else if (action === "dpms off") {
            if (!IdleInhibitor.preventSleep) {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "disable" })` : action);
                ScreenTime.setDpmsAsleep(true);
                dpmsRefreshTimer.restart();
            }
        } else if (action === "dpms on") {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "enable" })` : action);
            ScreenTime.setDpmsAsleep(false);
            dpmsRefreshTimer.restart();
        } else if (typeof action === "string") {
            Hypr.dispatch(Hypr.usingLua && ["dpms off", "dpms on"].includes(action) ? `hl.dsp.dpms({ action = "${action === "dpms off" ? "disable" : "enable"}" })` : action);
        } else if (!IdleInhibitor.preventSleep && !SessionManager.exec(action)) {
            Quickshell.execDetached(action);
        }
    }

    Timer {
        id: dpmsRefreshTimer

        interval: 200
        repeat: false
        onTriggered: Hyprland.refreshMonitors()
    }

    Connections {
        function onAboutToSleep(): void {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts.values

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
