import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    readonly property real chipSpacing: Tokens.spacing.large
    readonly property real nonAnimHeight: layout.implicitHeight + (IdleInhibitor.active ? activeChip.implicitHeight + root.chipSpacing : 0) + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    antialiasing: true
    clip: true

    GlassRim {
        z: 10
        radius: root.radius
    }

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            radius: Tokens.rounding.full
            color: IdleInhibitor.active ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                animate: true
                text: IdleInhibitor.preventLock ? "lock_clock" : "coffee"
                color: IdleInhibitor.active ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Tr.trCtx("Keep awake", "idle inhibitor")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (IdleInhibitor.preventLock)
                        return Tr.trCtx("Won't lock or sleep when idle", "idle inhibitor");
                    if (IdleInhibitor.preventSleep)
                        return Tr.trCtx("Won't sleep when idle, still locks", "idle inhibitor");
                    return Tr.trCtx("Normal power management", "idle inhibitor");
                }
                animate: true
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledRect {
            id: modePill

            readonly property real inset: Tokens.padding.extraSmall / 2
            readonly property var modes: [
                {
                    mode: IdleInhibitor.off,
                    icon: "close"
                },
                {
                    mode: IdleInhibitor.preventSleepMode,
                    icon: "coffee"
                },
                {
                    mode: IdleInhibitor.preventLockAndSleepMode,
                    icon: "lock_clock"
                }
            ]
            readonly property int currentIndex: Math.max(0, modes.findIndex(m => m.mode === IdleInhibitor.mode))
            readonly property real stageWidth: modes.length > 0 ? stages.implicitWidth / modes.length : 0

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: stages.implicitWidth + inset * 2
            implicitHeight: stages.implicitHeight + inset * 2
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHighest

            StyledRect {
                id: thumb

                x: modePill.inset + modePill.currentIndex * modePill.stageWidth
                y: modePill.inset
                width: modePill.stageWidth
                height: modePill.height - modePill.inset * 2
                radius: Tokens.rounding.full
                color: IdleInhibitor.active ? Colours.palette.m3secondary : Colours.palette.m3primary

                Behavior on x {
                    Anim {}
                }
            }

            Row {
                id: stages

                anchors.centerIn: parent

                Repeater {
                    model: modePill.modes

                    ModeStage {}
                }
            }
        }
    }

    Loader {
        id: activeChip

        anchors.top: layout.bottom
        anchors.left: parent.left
        anchors.topMargin: IdleInhibitor.active ? root.chipSpacing : -implicitHeight
        anchors.leftMargin: Tokens.padding.large

        opacity: IdleInhibitor.active ? 1 : 0
        scale: IdleInhibitor.active ? 1 : 0.5

        sourceComponent: StyledRect {
            implicitWidth: activeText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: activeText.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: activeText

                readonly property var since: IdleInhibitor.enabledSince
                readonly property bool hasSince: !isNaN(new Date(since).getTime())

                anchors.centerIn: parent
                // TRANSLATORS: %1 = a clock time, e.g. 14:30
                text: hasSince ? Tr.tr("Active since %1").arg(Qt.formatTime(new Date(since), Units.twelveHourClock ? "hh:mm a" : "hh:mm")) : ""
                color: Colours.palette.m3onPrimary
                font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.9)).build()
            }
        }

        Behavior on anchors.topMargin {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component ModeStage: StyledRect {
        id: stage

        required property var modelData

        readonly property bool selected: IdleInhibitor.mode === stage.modelData.mode

        implicitWidth: icon.implicitHeight + Tokens.padding.small * 2
        implicitHeight: icon.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: stage.modelData.icon
            color: stage.selected ? (IdleInhibitor.active ? Colours.palette.m3onSecondary : Colours.palette.m3onPrimary) : Colours.palette.m3onSurfaceVariant
            fill: stage.selected ? 1 : 0
            fontStyle: Tokens.font.icon.medium

            Behavior on fill {
                Anim {}
            }
        }

        StateLayer {
            onClicked: IdleInhibitor.mode = stage.modelData.mode
        }
    }
}
