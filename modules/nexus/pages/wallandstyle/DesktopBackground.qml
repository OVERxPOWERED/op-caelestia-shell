pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Desktop & background")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Desktop clock
        SectionHeader {
            first: true
            text: qsTr("Desktop clock")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Desktop clock")
            subtext: qsTr("Display clock widget directly on the desktop wallpaper")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        // Background audio visualiser
        SectionHeader {
            text: qsTr("Background audio visualiser")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Render live audio visualiser bars on the background")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            text: qsTr("Auto-hide")
            subtext: qsTr("Automatically hide visualiser when no audio is playing")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            text: qsTr("Blur effect")
            subtext: qsTr("Apply soft blur to background visualiser bars")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            label: qsTr("Bar rounding")
            subtext: qsTr("Corner rounding multiplier for visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.rounding
            from: 0
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            last: true
            label: qsTr("Bar spacing")
            subtext: qsTr("Spacing multiplier between visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.spacing
            from: 0.5
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }

        // Borders and rounding
        SectionHeader {
            text: qsTr("Borders & Rounding")
        }

        StepperRow {
            first: true
            label: qsTr("Border thickness")
            subtext: qsTr("Global border thickness (pixels)")
            value: Config.border.thickness
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            last: true
            label: qsTr("Corner rounding")
            subtext: qsTr("Global corner rounding radius (pixels)")
            value: Config.border.rounding
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = v
        }
    }
}
