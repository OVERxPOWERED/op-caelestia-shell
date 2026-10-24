pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    readonly property real cardWidth: Math.min(420, (root.width - Tokens.padding.large * 4) / Math.max(1, Math.min(3, Math.floor(root.width / 440))))
    readonly property real cardSpacing: Tokens.spacing.large

    implicitWidth: parent.width
    implicitHeight: 400

    Connections {
        target: OverviewState
        function onDragGlobalXChanged(): void {
            if (!OverviewState.draggingWorkspace || root.workspaces.length === 0 || !root.visible) return;
            const posInGrid = grid.mapFromItem(null, OverviewState.dragGlobalX, OverviewState.dragGlobalY);
            const cols = grid.columns;
            const stepX = root.cardWidth + root.cardSpacing;
            const cardHeight = root.cardWidth * (9 / 16) + 36;
            const stepY = cardHeight + root.cardSpacing;
            const col = Math.max(0, Math.min(cols - 1, Math.floor(posInGrid.x / stepX)));
            const row = Math.max(0, Math.floor(posInGrid.y / stepY));
            let slot = Math.max(0, Math.min(root.workspaces.length - 1, row * cols + col));
            if (slot !== OverviewState.dragTargetIndex) {
                OverviewState.dragTargetIndex = slot;
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        contentWidth: width
        contentHeight: grid.implicitHeight + Tokens.padding.large * 2
        clip: false
        boundsBehavior: Flickable.StopAtBounds
        interactive: !OverviewState.isDragging

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.medium
            columns: Math.max(1, Math.min(3, Math.floor((flickable.width - Tokens.padding.large * 2) / (root.cardWidth + root.cardSpacing))))
            spacing: root.cardSpacing

            Repeater {
                model: root.workspaces

                WorkspaceCard {
                    baseWidth: root.cardWidth
                    monitor: root.monitor
                    cardIndex: index

                    onClicked: {
                        OverviewState.focusWorkspace(modelData.id, () => root.closeRequested());
                    }
                }
            }

            // Dedicated "+" New Workspace Placeholder Card in Grid
            StyledRect {
                id: newWsCard
                implicitWidth: root.cardWidth
                implicitHeight: root.cardWidth * (9 / 16) + 36
                radius: Tokens.rounding.large

                readonly property bool isDropTarget: {
                    if (!OverviewState.isDragging || !OverviewState.draggingWindow) return false;
                    const pos = newWsCard.mapFromItem(null, OverviewState.dragGlobalX, OverviewState.dragGlobalY);
                    return pos.x >= 0 && pos.x <= width && pos.y >= 0 && pos.y <= height;
                }

                scale: isDropTarget ? 1.03 : (hoverHandler.hovered ? 1.01 : 1.0)
                color: isDropTarget
                    ? Colours.layer(Colours.palette.m3primaryContainer, 0.4)
                    : (hoverHandler.hovered ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 0.4) : Colours.layer(Colours.palette.m3surfaceContainer, 0))
                border.width: isDropTarget ? 2.5 : 1.5
                border.color: isDropTarget ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                Behavior on scale { Anim {} }
                Behavior on color { CAnim {} }
                Behavior on border.color { CAnim {} }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: Tokens.rounding.full
                        color: newWsCard.isDropTarget ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "add"
                            fontStyle: Tokens.font.icon.medium
                            color: newWsCard.isDropTarget ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: newWsCard.isDropTarget
                            ? qsTr("Drop to create Workspace %1").arg(OverviewState.nextAvailableWsId)
                            : qsTr("New Workspace (%1)").arg(OverviewState.nextAvailableWsId)
                        font.weight: Font.DemiBold
                        font.pixelSize: 13
                        color: newWsCard.isDropTarget ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Drop window here, or click to create")
                        font.pixelSize: 11
                        color: Colours.palette.m3outline
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        OverviewState.createNewWorkspace(() => root.closeRequested());
                    }
                }

                HoverHandler {
                    id: hoverHandler
                }
            }
        }
    }
}
