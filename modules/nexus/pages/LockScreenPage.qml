pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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
            id: patternRow

            property bool disabled: !GlobalConfig.lock.enablePattern

            Layout.fillWidth: true
            last: true
            implicitHeight: patternBtnLayout.implicitHeight + patternBtnLayout.anchors.margins * 2
            enabled: !disabled
            opacity: disabled ? 0.45 : 1.0

            RowLayout {
                id: patternBtnLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Record new pattern")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Draw a new 3x3 unlock pattern")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                IconTextButton {
                    icon: "edit"
                    text: qsTr("Set pattern")
                    type: IconTextButton.Tonal
                    disabled: patternRow.disabled
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
            text: qsTr("Legacy lock screen")
            subtext: qsTr("Use the original centered panel layout instead of independent frosted cards")
            checked: GlobalConfig.lock.useLegacyLayout
            onToggled: GlobalConfig.lock.useLegacyLayout = checked
        }

        SelectRow {
            id: designStyleRow

            label: qsTr("Design style")
            subtext: qsTr("Visual style and arrangement of lock screen components")
            disabled: GlobalConfig.lock.useLegacyLayout
            menuItems: designStyleItems.instances
            onSelected: item => GlobalConfig.lock.designStyle = item.value

            Binding {
                target: designStyleRow
                property: "active"
                value: designStyleItems.instances.find(i => i.value === GlobalConfig.lock.designStyle) ?? null
            }

            Variants {
                id: designStyleItems

                model: [
                    { id: "editorial", name: qsTr("Option 1 — Borderless editorial") },
                    { id: "hud", name: qsTr("Option 2 — Symmetric glass HUD") },
                    { id: "hero", name: qsTr("Option 3 — Split asymmetric hero") }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            label: qsTr("Background blur (%)")
            subtext: qsTr("Strength of the wallpaper or screen blur behind the lock screen")
            value: GlobalConfig.lock.backgroundBlur
            from: 0
            to: 100
            stepSize: 5
            onMoved: v => GlobalConfig.lock.backgroundBlur = v
        }

        ToggleRow {
            text: qsTr("Wallpaper background")
            subtext: qsTr("Display blurred desktop wallpaper behind lock screen")
            checked: GlobalConfig.lock.useWallpaper
            onToggled: GlobalConfig.lock.useWallpaper = checked
        }

        ToggleRow {
            text: qsTr("Show GIF")
            subtext: qsTr("Display animated GIF instead of system information")
            checked: GlobalConfig.lock.showGif
            onToggled: GlobalConfig.lock.showGif = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Recolour logo")
            subtext: qsTr("Tint the lock screen logo with the theme accent color")
            checked: GlobalConfig.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        // Components
        SectionHeader {
            text: qsTr("Components")
        }

        ToggleRow {
            first: true
            text: qsTr("Clock & date")
            subtext: qsTr("Show the clock and date in the center block")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showClock
            onToggled: GlobalConfig.lock.showClock = checked
        }

        ToggleRow {
            text: qsTr("Profile picture")
            subtext: qsTr("Show your user avatar in the center block")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showProfile
            onToggled: GlobalConfig.lock.showProfile = checked
        }

        ToggleRow {
            text: qsTr("Battery & power actions")
            subtext: qsTr("Show battery status and power menu button")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showActions
            onToggled: GlobalConfig.lock.showActions = checked
        }

        ToggleRow {
            text: qsTr("Weather card")
            subtext: qsTr("Show current weather and forecast card")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showWeather
            onToggled: GlobalConfig.lock.showWeather = checked
        }

        ToggleRow {
            text: qsTr("Resource card")
            subtext: qsTr("Show CPU, memory, and storage usage card")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showResources
            onToggled: GlobalConfig.lock.showResources = checked
        }

        ToggleRow {
            text: qsTr("Media card")
            subtext: qsTr("Show now playing media controls card")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showMedia
            onToggled: GlobalConfig.lock.showMedia = checked
        }

        ToggleRow {
            text: qsTr("GIF / Fetch card")
            subtext: qsTr("Show animated GIF or system fetch card")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showFetch
            onToggled: GlobalConfig.lock.showFetch = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Notification card")
            subtext: qsTr("Show notifications card on the lock screen")
            disabled: GlobalConfig.lock.useLegacyLayout
            checked: GlobalConfig.lock.showNotifs
            onToggled: GlobalConfig.lock.showNotifs = checked
        }

        // Layout Positions
        SectionHeader {
            text: qsTr("Component positions")
        }

        Repeater {
            id: posRepeater

            readonly property var positions: [
                { id: "top-left", name: qsTr("Top left") },
                { id: "top-center", name: qsTr("Top center") },
                { id: "top-right", name: qsTr("Top right") },
                { id: "center-left", name: qsTr("Center left") },
                { id: "center", name: qsTr("Center") },
                { id: "center-right", name: qsTr("Center right") },
                { id: "bottom-left", name: qsTr("Bottom left") },
                { id: "bottom-center", name: qsTr("Bottom center") },
                { id: "bottom-right", name: qsTr("Bottom right") }
            ]

            model: [
                { key: "centerPosition", label: qsTr("Center block"), subtext: qsTr("Clock, profile, password input, and power actions"), enabled: true },
                { key: "weatherPosition", label: qsTr("Weather card"), subtext: qsTr("Screen position for the weather card"), enabled: GlobalConfig.lock.showWeather },
                { key: "resourcesPosition", label: qsTr("Resource card"), subtext: qsTr("Screen position for the system resources card"), enabled: GlobalConfig.lock.showResources },
                { key: "mediaPosition", label: qsTr("Media card"), subtext: qsTr("Screen position for the media player card"), enabled: GlobalConfig.lock.showMedia || (GlobalConfig.lock.showFetch && !(GlobalConfig.lock.showGif && GlobalConfig.lock.fetchPlacement === "center")) },
                { key: "notifsPosition", label: qsTr("Notification card"), subtext: qsTr("Screen position for the notifications card"), enabled: GlobalConfig.lock.showNotifs }
            ]

            SelectRow {
                id: posRow

                required property var modelData
                required property int index

                first: index === 0
                last: false
                label: modelData.label
                subtext: modelData.subtext
                disabled: GlobalConfig.lock.useLegacyLayout || !modelData.enabled
                menuItems: posMenuItems.instances
                onSelected: item => GlobalConfig.lock[modelData.key] = item.value

                Binding {
                    target: posRow
                    property: "active"
                    value: posMenuItems.instances.find(i => i.value === GlobalConfig.lock[posRow.modelData.key]) ?? null
                }

                Variants {
                    id: posMenuItems

                    model: posRepeater.positions

                    MenuItem {
                        required property var modelData

                        text: modelData.name
                        value: modelData.id
                    }
                }
            }
        }

        SelectRow {
            id: fetchPlacementRow

            last: true
            label: qsTr("GIF / Fetch placement")
            subtext: qsTr("Place the GIF or fetch card above or below the media card, or behind the center block (GIF mode)")
            disabled: GlobalConfig.lock.useLegacyLayout || !GlobalConfig.lock.showFetch
            menuItems: fetchPlacementItems.instances
            onSelected: item => GlobalConfig.lock.fetchPlacement = item.value

            Binding {
                target: fetchPlacementRow
                property: "active"
                value: fetchPlacementItems.instances.find(i => i.value === GlobalConfig.lock.fetchPlacement) ?? null
            }

            Variants {
                id: fetchPlacementItems

                model: [
                    { id: "top", name: qsTr("Top of media card") },
                    { id: "bottom", name: qsTr("Bottom of media card") },
                    { id: "center", name: qsTr("Behind center block") }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
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
