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

    readonly property var workspaces: OverviewState.getNormalWorkspaces(monitor)
    readonly property real cardWidth: 420
    readonly property real cardSpacing: Tokens.spacing.large
    readonly property real sidePadding: Math.max(Tokens.padding.large, (root.width - cardWidth) / 2)

    implicitWidth: parent.width
    implicitHeight: 360

    function centerFocusedWorkspace(): void {
        const focusedId = Hypr.focusedWorkspace?.id;
        const idx = root.workspaces.findIndex(w => w && w.id === focusedId);
        if (idx >= 0) {
            const targetX = idx * (cardWidth + cardSpacing);
            flickable.contentX = Math.max(0, Math.min(Math.max(0, flickable.contentWidth - flickable.width), targetX));
        } else {
            flickable.contentX = 0;
        }
    }

    Component.onCompleted: Qt.callLater(centerFocusedWorkspace)

    Connections {
        target: Hypr
        function onFocusedWorkspaceChanged(): void {
            root.centerFocusedWorkspace();
        }
    }

    Connections {
        target: root
        function onWorkspacesChanged(): void {
            Qt.callLater(root.centerFocusedWorkspace);
        }
    }

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.bottom: pagination.top
        anchors.bottomMargin: Tokens.padding.medium
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: row.implicitWidth + root.sidePadding * 2
        contentHeight: height
        clip: false
        boundsBehavior: Flickable.StopAtBounds

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
                    model: root.workspaces

                    WorkspaceCard {
                        baseWidth: root.cardWidth
                        monitor: root.monitor

                        onClicked: {
                            OverviewState.focusWorkspace(modelData.id, () => root.closeRequested());
                        }
                    }
                }
            }
        }
    }

    // Pagination Dots
    Row {
        id: pagination
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.small
        visible: root.workspaces.length > 1

        Repeater {
            model: root.workspaces.length

            StyledRect {
                required property int index
                implicitWidth: (Hypr.focusedWorkspace?.id === root.workspaces[this.index]?.id) ? 18 : 6
                implicitHeight: 6
                radius: Tokens.rounding.full
                color: (Hypr.focusedWorkspace?.id === root.workspaces[this.index]?.id) ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                Behavior on implicitWidth { Anim {} }
                Behavior on color { CAnim {} }
            }
        }
    }
}
