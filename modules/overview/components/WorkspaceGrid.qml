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

    readonly property var liveWorkspaces: OverviewState.getNormalWorkspaces(monitor)
    // What the cards are built from. It is kept as it is while a workspace is dragged: any
    // change of the live list rebuilds every card, destroys the one holding the mouse and
    // cancels the drag, so a reorder could silently do nothing.
    property var workspaces: []

    function syncWorkspaces(): void {
        if (OverviewState.isDragging)
            return;
        const same = root.workspaces.length === root.liveWorkspaces.length
            && root.workspaces.every((ws, i) => ws === root.liveWorkspaces[i]);
        if (!same)
            root.workspaces = root.liveWorkspaces;
    }

    onLiveWorkspacesChanged: syncWorkspaces()
    Component.onCompleted: syncWorkspaces()

    Connections {
        function onIsDraggingChanged(): void {
            root.syncWorkspaces();
        }

        target: OverviewState
    }

    // Changes when the windows of the workspaces change, which is how a finished reorder shows up
    readonly property string contentSignature: root.workspaces.map(ws => ws.id + ":" + OverviewState.getToplevelsForWorkspace(ws.id).map(t => t.address).join("+")).join("|")

    onContentSignatureChanged: {
        if (OverviewState.dropPreview && !OverviewState.dropApplyPending)
            OverviewState.dropPreview = null;
    }
    readonly property real cardWidth: Math.min(420, (root.width - Tokens.padding.large * 4) / Math.max(1, Math.min(3, Math.floor(root.width / 440))))
    readonly property real cardSpacing: Tokens.spacing.large

    implicitWidth: parent.width
    implicitHeight: 400

    readonly property real cardHeight: root.cardWidth * (9 / 16) + 36
    readonly property real stepX: root.cardWidth + root.cardSpacing
    readonly property real stepY: root.cardHeight + root.cardSpacing

    // Top-left corner of a grid slot, relative to the grid
    function slotX(slot: int): real {
        return (slot % grid.columns) * root.stepX;
    }

    function slotY(slot: int): real {
        return Math.floor(slot / grid.columns) * root.stepY;
    }

    // Where a dragged workspace would be inserted: before the card at
    // insertRow * columns + insertCol (insertCol may equal the row length: after its last card)
    property int insertRow: -1
    property int insertCol: -1
    readonly property int insertIndex: insertRow * grid.columns + insertCol
    readonly property real nudge: 40

    function updateDragSlot(): void {
        if (!OverviewState.draggingWorkspace || root.workspaces.length === 0 || !root.visible)
            return;

        const cols = grid.columns;
        const count = root.workspaces.length;
        const rows = Math.ceil(count / cols);
        const pos = grid.mapFromItem(null, OverviewState.dragGlobalX, OverviewState.dragGlobalY);
        const row = Math.max(0, Math.min(rows - 1, Math.floor(pos.y / root.stepY)));
        const rowLength = Math.min(cols, count - row * cols);
        const card = Math.max(0, Math.min(rowLength - 1, Math.floor(pos.x / root.stepX)));
        const fraction = (pos.x - card * root.stepX) / root.cardWidth;

        // A margin around the middle of a card keeps the gap from flipping on the spot
        let col = root.insertCol;
        if (row !== root.insertRow || col < 0 || col > rowLength) {
            col = fraction < 0.5 ? card : card + 1;
        } else if (col === card && fraction > 0.58) {
            col = card + 1;
        } else if (col === card + 1 && fraction < 0.42) {
            col = card;
        } else if (col !== card && col !== card + 1) {
            col = fraction < 0.5 ? card : card + 1;
        }
        col = Math.max(0, Math.min(rowLength, col));

        root.insertRow = row;
        root.insertCol = col;

        // The workspace lands at the insertion point; removing it from its old place shifts later cards back
        const origin = OverviewState.dragOriginIndex;
        const insert = row * cols + col;
        const target = Math.max(0, Math.min(count - 1, insert > origin ? insert - 1 : insert));
        if (target !== OverviewState.dragTargetIndex)
            OverviewState.dragTargetIndex = target;
    }

    // Dropping where it already sits changes nothing, so no hint is shown
    readonly property bool gapShown: OverviewState.draggingWorkspace !== null && insertRow >= 0
        && insertIndex !== OverviewState.dragOriginIndex && insertIndex !== OverviewState.dragOriginIndex + 1

    Connections {
        function onDraggingWorkspaceChanged(): void {
            if (OverviewState.draggingWorkspace === null) {
                root.insertRow = -1;
                root.insertCol = -1;
            }
        }

        target: OverviewState
    }

    // Both axes matter: dragging straight down changes only Y
    Connections {
        function onDragGlobalXChanged(): void {
            root.updateDragSlot();
        }

        function onDragGlobalYChanged(): void {
            root.updateDragSlot();
        }

        target: OverviewState
    }

    // Scroll the grid while dragging near its top or bottom edge, so cards that are
    // out of view can be reached (the grid does not scroll by hand during a drag)
    readonly property real edgeZoneHeight: 90
    readonly property real maxContentY: Math.max(0, flickable.contentHeight - flickable.height)
    readonly property real cursorLocalY: (OverviewState.isDragging && root.visible)
        ? root.mapFromItem(null, 0, OverviewState.dragGlobalY).y
        : -1

    readonly property real upScrollFactor: {
        if (!OverviewState.isDragging || cursorLocalY > edgeZoneHeight || flickable.contentY <= 0)
            return 0;
        return Math.min(1, (edgeZoneHeight - cursorLocalY) / edgeZoneHeight);
    }

    readonly property real downScrollFactor: {
        if (!OverviewState.isDragging || cursorLocalY < (root.height - edgeZoneHeight) || flickable.contentY >= maxContentY)
            return 0;
        return Math.min(1, (cursorLocalY - (root.height - edgeZoneHeight)) / edgeZoneHeight);
    }

    Timer {
        interval: 16
        repeat: true
        running: root.upScrollFactor > 0 || root.downScrollFactor > 0
        onTriggered: {
            flickable.contentY = Math.max(0, Math.min(root.maxContentY, flickable.contentY + (root.downScrollFactor - root.upScrollFactor) * 16));
            // The cards moved under a cursor that stood still
            OverviewState.scrollRevision++;
            root.updateDragSlot();
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
                    id: card

                    baseWidth: root.cardWidth
                    monitor: root.monitor
                    cardIndex: index

                    // After a drop, the cards glide to where the new order puts them
                    readonly property int visualIndex: OverviewState.dropPreview
                        ? OverviewState.getVisualIndex(index, OverviewState.dropPreview.origin, OverviewState.dropPreview.target, true)
                        : index

                    // While dragging, the cards beside the gap move apart to show where the workspace
                    // would go: the two next to it the most, the pair after them half as much
                    readonly property real nudgeX: {
                        if (!root.gapShown || Math.floor(index / grid.columns) !== root.insertRow)
                            return 0;
                        const after = index - root.insertIndex;
                        const before = root.insertIndex - 1 - index;
                        if (after >= 0 && after <= 1)
                            return root.nudge / (after + 1);
                        if (before >= 0 && before <= 1)
                            return -root.nudge / (before + 1);
                        return 0;
                    }

                    transform: Translate {
                        x: root.slotX(card.visualIndex) - root.slotX(card.cardIndex) + card.nudgeX
                        y: root.slotY(card.visualIndex) - root.slotY(card.cardIndex)

                        Behavior on x {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    onClicked: {
                        OverviewState.focusWorkspace(modelData.id, () => root.closeRequested());
                    }
                }
            }

            // Dedicated "+" New Workspace Placeholder Card in Grid
            StyledRect {
                id: newWsCard
                implicitWidth: root.cardWidth
                implicitHeight: root.cardHeight
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
