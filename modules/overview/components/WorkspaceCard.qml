pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import ".."

Item {
    id: root

    required property HyprlandWorkspace modelData
    required property HyprlandMonitor monitor
    required property int index
    property int cardIndex: index
    property real baseWidth: 420
    property real baseHeight: baseWidth * (9 / 16)

    readonly property bool isFocused: Hypr.focusedWorkspace?.id === modelData?.id
    readonly property bool isActiveOnMonitor: monitor?.activeWorkspace?.id === modelData?.id
    readonly property bool isSelected: OverviewState.selectedCardIndex === cardIndex
    readonly property var toplevels: OverviewState.getToplevelsForWorkspace(modelData?.id ?? 0)

    // The window that was last active in this workspace (falls back to its first window)
    readonly property var activeToplevel: toplevels.find(t => `0x${t.address}` === modelData?.lastIpcObject?.lastwindow) ?? toplevels[0] ?? null
    readonly property string activeAppName: {
        const cls = activeToplevel?.lastIpcObject?.class ?? "";
        return DesktopEntries.heuristicLookup(cls)?.name || cls || activeToplevel?.title || "";
    }

    // What to call the workspace: its own name if it has one, otherwise the app you were using in it.
    // (Hyprland names a numbered workspace with its number, which used to show up as "2  2".)
    readonly property string label: {
        const raw = modelData?.name ?? "";
        const name = raw.startsWith("special:") ? raw.slice(8) : raw;
        if (name && name !== String(modelData?.id))
            return name;
        return activeAppName || qsTr("Empty");
    }

    signal clicked

    implicitWidth: baseWidth
    implicitHeight: baseHeight + 36

    readonly property bool isDropTarget: {
        if (!OverviewState.isDragging || !OverviewState.draggingWindow || !modelData) return false;
        const pos = root.mapFromItem(null, OverviewState.dragGlobalX, OverviewState.dragGlobalY);
        return pos.x >= 0 && pos.x <= root.width && pos.y >= 0 && pos.y <= root.height;
    }

    onIsDropTargetChanged: {
        if (isDropTarget) {
            OverviewState.dropTargetWsId = modelData.id;
        } else if (OverviewState.dropTargetWsId === modelData.id) {
            OverviewState.dropTargetWsId = -1;
        }
    }

    opacity: (OverviewState.draggingWorkspace === root.modelData) ? 0.35 : 1.0
    scale: hoverHandler.hovered || isSelected || isDropTarget ? 1.03 : (isFocused ? 1.01 : 1.0)
    Behavior on scale { Anim {} }
    Behavior on opacity { Anim {} }

    // Unified Card MouseArea for left-click focus/scroll and right-click workspace dragging (z: 0)
    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        z: 0
        preventStealing: isDraggingWs
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property bool isDraggingWs: false
        property point rightPressPos

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                rightPressPos = Qt.point(mouse.x, mouse.y);
                isDraggingWs = false;
            }
        }

        onPositionChanged: mouse => {
            if (pressed && (mouse.buttons & Qt.RightButton)) {
                const dx = mouse.x - rightPressPos.x;
                const dy = mouse.y - rightPressPos.y;
                if (!isDraggingWs && (dx * dx + dy * dy > 64)) {
                    isDraggingWs = true;
                    const globalPos = cardMouseArea.mapToItem(null, mouse.x, mouse.y);
                    OverviewState.startWorkspaceDrag(
                        root.modelData,
                        root.label,
                        globalPos.x,
                        globalPos.y,
                        root.cardIndex
                    );
                }
                if (isDraggingWs) {
                    const globalPos = cardMouseArea.mapToItem(null, mouse.x, mouse.y);
                    OverviewState.updateDrag(globalPos.x, globalPos.y);
                }
            }
        }

        onReleased: mouse => {
            if (isDraggingWs) {
                isDraggingWs = false;
                OverviewState.finishDrag();
            }
        }

        onCanceled: {
            if (isDraggingWs) {
                isDraggingWs = false;
                OverviewState.cancelDrag();
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.clicked();
            }
        }
    }

    // Top Card Header
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.extraSmall
            anchors.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            // Workspace number badge
            StyledRect {
                implicitWidth: 24
                implicitHeight: 24
                radius: Tokens.rounding.full
                color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: root.modelData?.id ?? ""
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.isFocused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                }
            }

            // Workspace Name
            StyledText {
                Layout.maximumWidth: root.width * 0.42
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            // Focused / Active Status Pill inside Header
            StyledRect {
                implicitWidth: statusText.implicitWidth + 14
                implicitHeight: 20
                radius: Tokens.rounding.full
                visible: root.isFocused || root.isActiveOnMonitor
                color: root.isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                StyledText {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.isFocused ? qsTr("Focused") : qsTr("Active")
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.isFocused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Window count badge
            Row {
                spacing: Tokens.spacing.extraSmall
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    text: root.toplevels.length
                    font.pixelSize: 12
                    color: Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                MaterialIcon {
                    text: "filter_none"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Main Card Body (16:9 Screen Preview Area) with rounded clipping
    StyledRect {
        id: cardBody

        anchors.top: header.bottom
        anchors.topMargin: Tokens.padding.extraSmall
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.baseHeight
        radius: Tokens.rounding.large

        color: Colours.layer(Colours.palette.m3surfaceContainer, 0)
        border.width: root.isDropTarget ? 2.5 : (root.isFocused ? 2 : (hoverHandler.hovered || root.isSelected ? 1.5 : 1))
        border.color: root.isDropTarget
            ? Colours.palette.m3primary
            : (root.isFocused
                ? Colours.palette.m3primary
                : (hoverHandler.hovered || root.isSelected ? Colours.palette.m3outline : Colours.palette.m3outlineVariant))

        Behavior on border.color { CAnim {} }
        Behavior on border.width { Anim {} }

        // Curved Content Wrapper (z: 1)
        ClippingWrapperRectangle {
            anchors.fill: parent
            anchors.margins: 1
            z: 1
            color: "transparent"
            radius: Tokens.rounding.large

            Item {
                anchors.fill: parent

                // Wallpaper preview inside desktop card
                Image {
                    id: wallPreview
                    anchors.fill: parent
                    source: Wallpapers.current ? `file://${Wallpapers.current}` : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.35
                    asynchronous: true
                }

                // Miniature windows viewport (z: 2)
                Item {
                    id: innerViewport
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    z: 2

                    Repeater {
                        model: root.toplevels

                        MiniWindow {
                            monitor: root.monitor
                            cardWidth: innerViewport.width
                            cardHeight: innerViewport.height
                        }
                    }
                }
            }
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
