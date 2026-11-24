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
        if (FocusTimer.phase === "shortBreak")
            return Colours.palette.m3tertiary;
        if (FocusTimer.phase === "longBreak")
            return Colours.palette.m3secondary;
        return Colours.palette.m3primary;
    }

    readonly property string phaseIconName: FocusTimer.isStopwatch ? "waves" : FocusTimer.phaseIcon

    readonly property string shortPhaseLabel: {
        if (FocusTimer.phase === "shortBreak")
            return Tr.tr("Break");
        if (FocusTimer.phase === "longBreak")
            return Tr.tr("Big break");
        return FocusTimer.isStopwatch ? Tr.tr("Flow") : Tr.tr("Focus");
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: event => {
                    if (event.button === Qt.RightButton) {
                        if (FocusTimer.canSwitchMode)
                            FocusTimer.setMode(FocusTimer.mode === "stopwatch" ? "timer" : "stopwatch");
                        return;
                    }
                    const phases = ["focus", "shortBreak", "longBreak"];
                    const idx = phases.indexOf(FocusTimer.phase);
                    FocusTimer.setPhase(phases[(idx + 1) % phases.length]);
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.pomodoroColour, 0.16)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            text: root.phaseIconName
                            color: root.pomodoroColour
                        }

                        StyledText {
                            text: root.shortPhaseLabel
                            font: Tokens.font.label.small
                            color: root.pomodoroColour
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Active subject chip (visible when a subject is chosen in the Focus tab)
        StyledRect {
            id: subjectBadge

            anchors.top: topBar.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Tokens.padding.extraSmall
            visible: FocusTimer.phase === "focus" && FocusTimer.subject.length > 0
            implicitWidth: Math.min(parent.width - Tokens.padding.small * 2, subjectText.implicitWidth + Tokens.padding.small * 2)
            implicitHeight: visible ? subjectText.implicitHeight + 4 : 0
            radius: Tokens.rounding.full
            color: Colours.palette.m3secondaryContainer
            z: 10

            StyledText {
                id: subjectText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Tokens.padding.small
                anchors.verticalCenter: parent.verticalCenter
                text: FocusTimer.subject
                font: Tokens.font.label.small
                color: Colours.palette.m3onSecondaryContainer
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Middle Vessel: Rising wavy fluid fill behind vertical timer digits
        Item {
            id: vesselArea

            anchors.top: subjectBadge.visible ? subjectBadge.bottom : topBar.bottom
            anchors.bottom: bottomControls.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.padding.small
            anchors.bottomMargin: Tokens.padding.small
            anchors.leftMargin: Tokens.padding.extraSmall
            anchors.rightMargin: Tokens.padding.extraSmall

            // Layer 1: Smooth dual-layer wavy fluid rising with FocusTimer.progress
            PomodoroShapes {
                anchors.fill: parent
                accentColour: root.pomodoroColour
                z: 1
            }

            // Layer 2: Big Vertical Graphic Timer Digits
            StyledText {
                id: verticalTimerText

                anchors.centerIn: parent
                rotation: 90
                text: FocusTimer.display
                color: Colours.palette.m3onSurface
                font: Tokens.font.clock.size(FocusTimer.display.length > 5 ? 30 : 38).weight(Font.Bold).build()
                z: 2

                Behavior on color {
                    CAnim {}
                }
            }
        }

        // Bottom Controls: Elevated above vessel with generous breathing room
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
                    model: FocusTimer.cyclesBeforeLongBreak

                    StyledRect {
                        required property int index

                        width: 5
                        height: 5
                        radius: 2.5
                        color: index < FocusTimer.cycleCount
                            ? root.pomodoroColour
                            : (index === FocusTimer.cycleCount && FocusTimer.phase === "focus"
                                ? Qt.alpha(root.pomodoroColour, 0.6)
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
                    icon: FocusTimer.running ? "pause" : "play_arrow"
                    activeColour: root.pomodoroColour
                    font: Tokens.font.icon.small
                    implicitWidth: 30
                    implicitHeight: 30
                    onClicked: FocusTimer.toggle()
                }

                IconButton {
                    type: IconButton.Tonal
                    icon: "skip_next"
                    font: Tokens.font.icon.small
                    disabled: !FocusTimer.sessionActive
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: FocusTimer.skipPhase()
                }

                IconButton {
                    type: IconButton.Text
                    icon: "replay"
                    font: Tokens.font.icon.small
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: FocusTimer.reset()
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

            // Running Focus badge at bottom if timer active while viewing clock
            CustomMouseArea {
                Layout.topMargin: Tokens.padding.extraSmall
                Layout.alignment: Qt.AlignHCenter
                visible: FocusTimer.running || FocusTimer.sessionActive
                implicitWidth: badgeRow.implicitWidth + Tokens.padding.small * 2
                implicitHeight: badgeRow.implicitHeight + Tokens.padding.extraSmall

                onClicked: root.showPomodoro = true

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.pomodoroColour, 0.2)

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 2

                        MaterialIcon {
                            text: root.phaseIconName
                            color: root.pomodoroColour
                        }

                        StyledText {
                            text: FocusTimer.display
                            color: root.pomodoroColour
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }
    }
}
