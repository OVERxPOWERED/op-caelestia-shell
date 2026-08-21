pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import ".."

Item {
    id: root

    required property HyprlandMonitor monitor
    signal closeRequested

    readonly property var specialWorkspaces: OverviewState.getSpecialWorkspaces()
    readonly property real cardWidth: 420
    readonly property real cardSpacing: Tokens.spacing.large
    readonly property real sidePadding: Math.max(Tokens.padding.large, (root.width - cardWidth) / 2)

    implicitWidth: parent.width
    implicitHeight: 360

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: row.implicitWidth + root.sidePadding * 2
        contentHeight: height
        clip: false
        boundsBehavior: Flickable.StopAtBounds
        visible: root.specialWorkspaces.length > 0

        Behavior on contentX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: container
            width: flickable.contentWidth
            height: flickable.height

            Row {
                id: row
                x: root.sidePadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.cardSpacing

                Repeater {
                    model: root.specialWorkspaces

                    WorkspaceCard {
                        baseWidth: root.cardWidth
                        monitor: root.monitor

                        onClicked: {
                            OverviewState.toggleSpecialWorkspace(modelData.name, () => root.closeRequested());
                        }
                    }
                }
            }
        }
    }

    // Empty State if no scratchpads exist
    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.medium
        visible: root.specialWorkspaces.length === 0

        StyledRect {
            implicitWidth: 64
            implicitHeight: 64
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainerHigh
            anchors.horizontalCenter: parent.horizontalCenter

            MaterialIcon {
                anchors.centerIn: parent
                text: "view_compact"
                fontStyle: Tokens.font.icon.extraLarge
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            text: qsTr("No Active Scratchpads")
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: Colours.palette.m3onSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: qsTr("Use 'special:<name>' workspaces to manage background scratchpad windows")
            font.pixelSize: 12
            color: Colours.palette.m3onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
