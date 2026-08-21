pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "./lock"

PageBase {
    id: root

    title: qsTr("Lock screen")

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Authentication
        SectionHeader {
            first: true
            text: qsTr("Authentication")
        }

        ToggleRow {
            first: true
            text: qsTr("Pattern unlock")
            subtext: qsTr("Unlock using a 3x3 touch or mouse pattern instead of password")
            checked: GlobalConfig.lock.enablePattern
            onToggled: GlobalConfig.lock.enablePattern = checked
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: patternBtnLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: patternBtnLayout

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "gesture"
                    color: Colours.palette.m3primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: qsTr("Record new pattern")
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        text: qsTr("Draw a new 3x3 unlock pattern")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }

                IconTextButton {
                    icon: "edit"
                    text: qsTr("Set pattern")
                    type: IconTextButton.Tonal
                    onClicked: patternModal.active = true
                }
            }
        }

        // Biometrics
        SectionHeader {
            text: qsTr("Biometrics")
        }

        ToggleRow {
            first: true
            text: qsTr("Fingerprint unlock")
            subtext: qsTr("Authenticate with fingerprint reader via fprintd")
            checked: GlobalConfig.lock.enableFprint
            onToggled: GlobalConfig.lock.enableFprint = checked
        }

        StepperRow {
            label: qsTr("Max fingerprint attempts")
            subtext: qsTr("Attempts allowed before locking to password only")
            disabled: !GlobalConfig.lock.enableFprint
            value: GlobalConfig.lock.maxFprintTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxFprintTries = v
        }

        ToggleRow {
            text: qsTr("Face unlock (Howdy)")
            subtext: qsTr("Authenticate using infrared facial recognition")
            checked: GlobalConfig.lock.enableHowdy
            onToggled: GlobalConfig.lock.enableHowdy = checked
        }

        StepperRow {
            label: qsTr("Max face unlock attempts")
            subtext: qsTr("Attempts allowed before locking to password")
            disabled: !GlobalConfig.lock.enableHowdy
            value: GlobalConfig.lock.maxHowdyTries
            from: 1
            to: 5
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxHowdyTries = v
        }

        ToggleRow {
            last: true
            text: qsTr("Trigger face unlock on wake")
            subtext: qsTr("Immediately attempt facial scan when display wakes up")
            disabled: !GlobalConfig.lock.enableHowdy
            checked: GlobalConfig.lock.triggerHowdyOnWake
            onToggled: GlobalConfig.lock.triggerHowdyOnWake = checked
        }

        // Appearance
        SectionHeader {
            text: qsTr("Appearance")
        }

        ToggleRow {
            first: true
            text: qsTr("Wallpaper background")
            subtext: qsTr("Display blurred desktop wallpaper behind lock screen")
            checked: GlobalConfig.lock.useWallpaper
            onToggled: GlobalConfig.lock.useWallpaper = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Recolour logo")
            subtext: qsTr("Tint the lock screen logo with the theme accent color")
            checked: GlobalConfig.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        // Modal popup for pattern recording
        Loader {
            id: patternModal
            active: false
            visible: active
            parent: root
            x: 0
            y: 0
            width: root.width
            height: root.height
            z: 99

            sourceComponent: Item {
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.65)

                    TapHandler {
                        onTapped: patternModal.active = false
                    }
                }

                StyledRect {
                    anchors.centerIn: parent
                    implicitWidth: dialogContent.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: dialogContent.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainer

                    PatternRecordDialog {
                        id: dialogContent
                        anchors.centerIn: parent
                        onFinished: success => patternModal.active = false
                    }
                }
            }
        }
    }
}
