pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Taskbar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Behaviour
        SectionHeader {
            first: true
            text: qsTr("Behaviour")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Persistent")
            subtext: qsTr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Workspaces
        SectionHeader {
            text: qsTr("Workspaces")
        }

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Shown")
            subtext: qsTr("Number of workspaces displayed")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Active indicator")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Active trail")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Occupied background")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show windows")
            subtext: qsTr("Show icons of open windows on each workspace")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Windows on special workspaces")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Max window icons")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Per-monitor workspaces")
            subtext: qsTr("Show each monitor's workspaces independently")
            checked: GlobalConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: GlobalConfig.bar.workspaces.perMonitorWorkspaces = checked
        }

        // Active window
        SectionHeader {
            text: qsTr("Active window")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Compact")
            checked: Config.bar.activeWindow.compact
            onToggled: GlobalConfig.bar.activeWindow.compact = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Inverted")
            checked: Config.bar.activeWindow.inverted
            onToggled: GlobalConfig.bar.activeWindow.inverted = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Show on hover")
            checked: Config.bar.activeWindow.showOnHover
            onToggled: GlobalConfig.bar.activeWindow.showOnHover = checked
        }

        // Tray
        SectionHeader {
            text: qsTr("Tray")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Background")
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Recolour icons")
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Compact")
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        // Status icons
        SectionHeader {
            text: qsTr("Status icons")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Speakers")
            checked: Config.bar.status.showAudio
            onToggled: GlobalConfig.bar.status.showAudio = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Microphone")
            checked: Config.bar.status.showMicrophone
            onToggled: GlobalConfig.bar.status.showMicrophone = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Keyboard layout")
            checked: Config.bar.status.showKbLayout
            onToggled: GlobalConfig.bar.status.showKbLayout = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Network")
            checked: Config.bar.status.showNetwork
            onToggled: GlobalConfig.bar.status.showNetwork = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Wi-Fi")
            checked: Config.bar.status.showWifi
            onToggled: GlobalConfig.bar.status.showWifi = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Bluetooth")
            checked: Config.bar.status.showBluetooth
            onToggled: GlobalConfig.bar.status.showBluetooth = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Battery")
            checked: Config.bar.status.showBattery
            onToggled: GlobalConfig.bar.status.showBattery = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Caps lock")
            checked: Config.bar.status.showLockStatus
            onToggled: GlobalConfig.bar.status.showLockStatus = checked
        }

        // Clock
        SectionHeader {
            text: qsTr("Clock")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Background")
            checked: Config.bar.clock.background
            onToggled: GlobalConfig.bar.clock.background = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show date")
            checked: Config.bar.clock.showDate
            onToggled: GlobalConfig.bar.clock.showDate = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Show icon")
            checked: Config.bar.clock.showIcon
            onToggled: GlobalConfig.bar.clock.showIcon = checked
        }

        // Scroll actions
        SectionHeader {
            text: qsTr("Scroll actions")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Workspaces")
            subtext: qsTr("Scroll over the bar to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }

        // Popouts
        SectionHeader {
            text: qsTr("Popouts")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Active window")
            checked: Config.bar.popouts.activeWindow
            onToggled: GlobalConfig.bar.popouts.activeWindow = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Tray")
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Status icons")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
        }
    }
}
