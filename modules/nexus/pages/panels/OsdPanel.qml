pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("On-screen display")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Enabled")
            subtext: qsTr("Show floating on-screen indicators when adjusting volume or brightness")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        // Overlays
        SectionHeader {
            text: qsTr("Overlays")
        }

        ToggleRow {
            first: true
            text: qsTr("Brightness")
            subtext: qsTr("Show indicator when adjusting display brightness")
            disabled: !Config.osd.enabled
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Microphone")
            subtext: qsTr("Show indicator when muting or unmuting the microphone")
            disabled: !Config.osd.enabled
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }

        // Timing
        SectionHeader {
            text: qsTr("Timing")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Hide delay")
            subtext: qsTr("Milliseconds before the indicator automatically disappears")
            disabled: !Config.osd.enabled
            value: Config.osd.hideDelay
            from: 500
            to: 6000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }
    }
}
