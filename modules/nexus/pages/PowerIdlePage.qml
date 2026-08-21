pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Power & idle")

    function getTimeout(action: string, defaultSec: int): int {
        const list = GlobalConfig.general.idle.timeouts;
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            if (item.idleAction === action)
                return item.timeout;
            if (Array.isArray(item.idleAction) && item.idleAction.includes(action))
                return item.timeout;
        }
        return defaultSec;
    }

    function updateTimeout(action: string, seconds: int, returnAct: string): void {
        const list = JSON.parse(JSON.stringify(GlobalConfig.general.idle.timeouts));
        let found = false;
        for (let i = 0; i < list.length; i++) {
            if (list[i].idleAction === action || (Array.isArray(list[i].idleAction) && list[i].idleAction.includes(action))) {
                list[i].timeout = seconds;
                found = true;
                break;
            }
        }
        if (!found) {
            const entry = { "idleAction": action, "timeout": seconds };
            if (returnAct)
                entry.returnAction = returnAct;
            list.push(entry);
        }
        GlobalConfig.general.idle.timeouts = list;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Battery
        SectionHeader {
            first: true
            text: qsTr("Battery management")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Critical hibernate level")
            subtext: qsTr("Battery percentage that triggers automatic hibernation (%)")
            value: GlobalConfig.general.battery.criticalLevel
            from: 1
            to: 15
            stepSize: 1
            onMoved: v => GlobalConfig.general.battery.criticalLevel = v
        }

        // Idle & Sleep
        SectionHeader {
            text: qsTr("Idle & Sleep")
        }

        ToggleRow {
            first: true
            text: qsTr("Inhibit sleep during audio")
            subtext: qsTr("Keep system awake while media or music is playing")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            text: qsTr("Inhibit sleep when plugged in")
            subtext: qsTr("Keep system awake while charging on AC power")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Lock before sleep")
            subtext: qsTr("Automatically lock the session before system suspends")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        // Timeouts
        SectionHeader {
            text: qsTr("Inactivity timeouts")
        }

        StepperRow {
            first: true
            label: qsTr("Lock screen timeout")
            subtext: qsTr("Minutes of inactivity before locking the screen")
            value: Math.round(root.getTimeout("lock", 180) / 60)
            from: 1
            to: 60
            stepSize: 1
            onMoved: v => root.updateTimeout("lock", v * 60, "")
        }

        StepperRow {
            label: qsTr("Display turn-off (DPMS)")
            subtext: qsTr("Minutes of inactivity before turning displays off")
            value: Math.round(root.getTimeout("dpms off", 300) / 60)
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => root.updateTimeout("dpms off", v * 60, "dpms on")
        }

        StepperRow {
            last: true
            label: qsTr("Suspend / Hibernate timeout")
            subtext: qsTr("Minutes of inactivity before putting system to sleep")
            value: Math.round(root.getTimeout("suspendThenHibernate", 600) / 60)
            from: 2
            to: 240
            stepSize: 2
            onMoved: v => root.updateTimeout("suspendThenHibernate", v * 60, "")
        }
    }
}
