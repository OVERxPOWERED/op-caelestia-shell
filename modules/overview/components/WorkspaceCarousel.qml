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

    readonly property real edgeZoneWidth: 140
    readonly property real maxContentX: Math.max(0, flickable.contentWidth - flickable.width)

    // Cursor position in carousel coordinates
    readonly property real cursorLocalX: (OverviewState.isDragging && root.visible)
        ? root.mapFromItem(null, OverviewState.dragGlobalX, 0).x
        : -1

    // Dynamic scroll factors (0.0 to 1.0) with quadratic/power curve acceleration
    readonly property real leftScrollFactor: {
        if (!OverviewState.isDragging || cursorLocalX < 0 || cursorLocalX > edgeZoneWidth || flickable.contentX <= 0)
            return 0;
        return Math.max(0, Math.min(1, (edgeZoneWidth - cursorLocalX) / edgeZoneWidth));
    }

    readonly property real rightScrollFactor: {
        if (!OverviewState.isDragging || cursorLocalX < (root.width - edgeZoneWidth) || flickable.contentX >= maxContentX)
            return 0;
        return Math.max(0, Math.min(1, (cursorLocalX - (root.width - edgeZoneWidth)) / edgeZoneWidth));
    }

    readonly property bool isEdgeScrollingLeft: leftScrollFactor > 0
    readonly property bool isEdgeScrollingRight: rightScrollFactor > 0
    readonly property bool isEdgeScrolling: isEdgeScrollingLeft || isEdgeScrollingRight

    function updateDragSlot(): void {
        if (!OverviewState.draggingWorkspace || root.workspaces.length === 0) return;
        const posInContainer = container.mapFromItem(null, OverviewState.dragGlobalX, 0).x;
        const step = root.cardWidth + root.cardSpacing;
        const relativeX = posInContainer - root.sidePadding;
        let slot = Math.floor((relativeX + root.cardSpacing / 2) / step);
        slot = Math.max(0, Math.min(root.workspaces.length - 1, slot));
        if (slot !== OverviewState.dragTargetIndex) {
            OverviewState.dragTargetIndex = slot;
        }
    }

    Timer {
        id: edgeScrollTimer
        interval: 16
        running: root.isEdgeScrolling
        repeat: true
        onTriggered: {
            if (root.leftScrollFactor > 0) {
                const speed = 920 * Math.pow(root.leftScrollFactor, 1.4);
                flickable.contentX = Math.max(0, flickable.contentX - speed * 0.016);
            } else if (root.rightScrollFactor > 0) {
                const speed = 920 * Math.pow(root.rightScrollFactor, 1.4);
                flickable.contentX = Math.min(root.maxContentX, flickable.contentX + speed * 0.016);
            }
            root.updateDragSlot();
        }
    }

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

    Connections {
        target: OverviewState
        function onDragGlobalXChanged(): void {
            root.updateDragSlot();
        }
    }

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.bottom: pagination.top
        anchors.bottomMargin: Tokens.padding.medium
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: root.sidePadding * 2 + (root.workspaces.length + 1) * (root.cardWidth + root.cardSpacing)
        contentHeight: height
        clip: false
        boundsBehavior: Flickable.StopAtBounds
        interactive: !OverviewState.isDragging

        Behavior on contentX {
            enabled: !flickable.dragging && !root.isEdgeScrolling && !OverviewState.isDragging
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        WheelHandler {
            target: flickable
            property: "contentX"
            rotationScale: 1.5
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        Item {
            id: container
            width: flickable.contentWidth
            height: flickable.height

            Repeater {
                model: root.workspaces

                WorkspaceCard {
                    id: cardItem
                    baseWidth: root.cardWidth
                    monitor: root.monitor
                    cardIndex: index

                    readonly property int visualIndex: OverviewState.getVisualIndex(
                        index,
                        OverviewState.dragOriginIndex,
                        OverviewState.dragTargetIndex,
                        OverviewState.draggingWorkspace !== null
                    )

                    x: root.sidePadding + visualIndex * (root.cardWidth + root.cardSpacing)
                    anchors.verticalCenter: container.verticalCenter

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    onClicked: {
                        OverviewState.focusWorkspace(modelData.id, () => root.closeRequested());
                    }
                }
            }

            // Dedicated "+" New Workspace Placeholder Card
            StyledRect {
                id: newWsCard
                x: root.sidePadding + root.workspaces.length * (root.cardWidth + root.cardSpacing)
                anchors.verticalCenter: container.verticalCenter
                width: root.cardWidth
                height: root.cardWidth * (9 / 16) + 36
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
                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

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

    // Left Edge Glow Indicator
    Rectangle {
        id: leftEdgeGlow
        anchors.left: parent.left
        anchors.top: flickable.top
        anchors.bottom: flickable.bottom
        width: 90
        z: 20
        enabled: false
        visible: opacity > 0
        opacity: root.isEdgeScrollingLeft ? (0.2 + 0.4 * root.leftScrollFactor) : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colours.palette.m3primary }
            GradientStop { position: 1.0; color: "transparent" }
        }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_left"
            fontStyle: Tokens.font.icon.large
            color: Colours.palette.m3onPrimary
            opacity: 0.9
        }
    }

    // Right Edge Glow Indicator
    Rectangle {
        id: rightEdgeGlow
        anchors.right: parent.right
        anchors.top: flickable.top
        anchors.bottom: flickable.bottom
        width: 90
        z: 20
        enabled: false
        visible: opacity > 0
        opacity: root.isEdgeScrollingRight ? (0.2 + 0.4 * root.rightScrollFactor) : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Colours.palette.m3primary }
        }

        MaterialIcon {
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_right"
            fontStyle: Tokens.font.icon.large
            color: Colours.palette.m3onPrimary
            opacity: 0.9
        }
    }
}
