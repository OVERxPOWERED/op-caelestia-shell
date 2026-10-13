pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.dateTimeWidth

    property bool showPomodoro: GlobalConfig.dashboard.pomodoro.defaultToPomodoro

    readonly property color pomodoroColour: {
        switch (Pomodoro.mode) {
        case Pomodoro.Mode.ShortBreak:
            return Colours.palette.m3tertiary;
        case Pomodoro.Mode.LongBreak:
            return Colours.palette.m3secondary;
        default:
            return Colours.palette.m3primary;
        }
    }

    // Switcher button in top-right (available across both views)
    IconButton {
        id: switchBtn

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall
        z: 20

        type: IconButton.Text
        icon: root.showPomodoro ? "schedule" : "timer"
        font: Tokens.font.icon.small
        implicitHeight: 24
        implicitWidth: 24

        onClicked: root.showPomodoro = !root.showPomodoro
    }

    // ── Pomodoro View ─────────────────────────────────────────────────────────
    Item {
        id: pomodoroView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.showPomodoro ? 1 : 0
        scale: root.showPomodoro ? 1 : 0.95

        Behavior on opacity {
            Anim { type: Anim.FastEffects }
        }
        Behavior on scale {
            Anim { type: Anim.DefaultSpatial }
        }

        // Top bar with mode switcher
        Item {
            id: topBar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: switchBtn.width + Tokens.padding.extraSmall * 2
            anchors.margins: Tokens.padding.extraSmall
            height: 24
            z: 10

            CustomMouseArea {
                anchors.fill: parent

                onClicked: {
                    const nextMode = (Pomodoro.mode + 1) % 3;
                    Pomodoro.setMode(nextMode);
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.pomodoroColour, 0.16)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            text: Pomodoro.modeIcon
                            color: root.pomodoroColour
                        }

                        StyledText {
                            text: Pomodoro.shortModeName
                            font: Tokens.font.label.small
                            color: root.pomodoroColour
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Middle Vessel: Big Vertical Background Timer Digits submerged by falling translucent M3 shapes
        Item {
            id: vesselArea

            anchors.top: topBar.bottom
            anchors.bottom: bottomControls.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.padding.small
            anchors.bottomMargin: Tokens.padding.small
            clip: true

            // Layer 1: Big Vertical Graphic Timer Digits
            StyledText {
                id: verticalTimerText

                anchors.centerIn: parent
                rotation: 90
                text: Pomodoro.formattedTime
                color: Qt.alpha(Colours.palette.m3onSurface, 0.75)
                font: Tokens.font.clock.size(38).weight(Font.Bold).build()
                z: 1

                Behavior on color {
                    CAnim {}
                }
            }

            // Layer 2: Falling & Settling Heap of Translucent Material 3 Shapes
            PomodoroShapes {
                anchors.fill: parent
                z: 2
            }
        }

        // Bottom Controls: Elevated above shapes with generous breathing room
        ColumnLayout {
            id: bottomControls

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small
            z: 10

            // Cycle progress dots
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5

                Repeater {
                    model: Pomodoro.sessionsBeforeLongBreak

                    StyledRect {
                        required property int index

                        width: 5
                        height: 5
                        radius: 2.5
                        color: index < Pomodoro.cycleCount
                            ? Colours.palette.m3primary
                            : (index === Pomodoro.cycleCount && Pomodoro.mode === Pomodoro.Mode.Focus
                                ? Qt.alpha(Colours.palette.m3primary, 0.6)
                                : Colours.tPalette.m3outline)

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }
            }

            // Control buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    type: IconButton.Filled
                    icon: Pomodoro.running ? "pause" : "play_arrow"
                    activeColour: root.pomodoroColour
                    font: Tokens.font.icon.small
                    implicitWidth: 30
                    implicitHeight: 30
                    onClicked: Pomodoro.toggle()
                }

                IconButton {
                    type: IconButton.Tonal
                    icon: "skip_next"
                    font: Tokens.font.icon.small
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: Pomodoro.skip()
                }

                IconButton {
                    type: IconButton.Text
                    icon: "replay"
                    font: Tokens.font.icon.small
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: Pomodoro.reset()
                }
            }
        }
    }

    // ── Clock View ───────────────────────────────────────────────────────────
    Item {
        id: clockView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.showPomodoro ? 0 : 1
        scale: root.showPomodoro ? 0.95 : 1

        Behavior on opacity {
            Anim { type: Anim.FastEffects }
        }
        Behavior on scale {
            Anim { type: Anim.DefaultSpatial }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                Layout.bottomMargin: -(font.pointSize * 0.4)
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                color: Colours.palette.m3secondary
                font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "•••"
                color: Colours.palette.m3primary
                font: Tokens.font.clock.size(28 * 0.9).build()
            }

            StyledText {
                Layout.topMargin: -(font.pointSize * 0.4)
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                color: Colours.palette.m3secondary
                font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
            }

            Loader {
                Layout.topMargin: -(((item as StyledText)?.font.pointSize ?? 0) * 0.4)
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Config.dashboard.showClockSeconds
                visible: active

                sourceComponent: StyledText {
                    text: "•••"
                    color: Colours.palette.m3primary
                    font: Tokens.font.clock.size(28 * 0.9).build()
                }
            }
            Loader {
                Layout.topMargin: -(((item as StyledText)?.font.pointSize ?? 0) * 0.4)
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Config.dashboard.showClockSeconds
                visible: active

                sourceComponent: StyledText {
                    text: Time.format("ss")
                    color: Colours.palette.m3secondary
                    font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
                }
            }

            Loader {
                asynchronous: true
                Layout.alignment: Qt.AlignHCenter

                active: Units.twelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: Time.amPmStr
                    color: Colours.palette.m3primary
                    font: Tokens.font.clock.size(18).weight(Font.DemiBold).build()
                }
            }

            // Running Pomodoro badge at bottom if timer active while viewing clock
            CustomMouseArea {
                Layout.topMargin: Tokens.padding.extraSmall
                Layout.alignment: Qt.AlignHCenter
                visible: Pomodoro.running
                implicitWidth: badgeRow.implicitWidth + Tokens.padding.small * 2
                implicitHeight: badgeRow.implicitHeight + Tokens.padding.extraSmall

                onClicked: root.showPomodoro = true

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3primary, 0.2)

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 2

                        MaterialIcon {
                            text: Pomodoro.modeIcon
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: Pomodoro.formattedTime
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }
    }
}
