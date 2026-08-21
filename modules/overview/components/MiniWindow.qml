pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import ".."

Item {
    id: root

    required property HyprlandToplevel modelData
    required property HyprlandMonitor monitor
    required property real cardWidth
    required property real cardHeight
    property bool isHighlighted: false

    readonly property var ipc: modelData?.lastIpcObject ?? ({})
    readonly property list<int> at: ipc.at ?? [0, 0]
    readonly property list<int> size: ipc.size ?? [100, 100]

    readonly property real monX: monitor?.x ?? 0
    readonly property real monY: monitor?.y ?? 0
    readonly property real monW: (monitor?.width && monitor.width > 0) ? monitor.width : 1920
    readonly property real monH: (monitor?.height && monitor.height > 0) ? monitor.height : 1080

    readonly property real targetX: Math.max(0, Math.min(cardWidth - 20, (at[0] - monX) / monW * cardWidth))
    readonly property real targetY: Math.max(0, Math.min(cardHeight - 20, (at[1] - monY) / monH * cardHeight))
    readonly property real targetW: Math.max(36, Math.min(cardWidth - targetX, size[0] / monW * cardWidth))
    readonly property real targetH: Math.max(28, Math.min(cardHeight - targetY, size[1] / monH * cardHeight))

    x: targetX
    y: targetY
    width: targetW
    height: targetH

    Behavior on x { Anim {} }
    Behavior on y { Anim {} }
    Behavior on width { Anim {} }
    Behavior on height { Anim {} }

    // Drag support
    Drag.active: dragArea.drag.active
    Drag.source: root.modelData
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    StyledRect {
        id: bg

        anchors.fill: parent
        radius: Tokens.rounding.small

        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
        border.width: root.isHighlighted || hoverHandler.hovered ? 1.5 : 1
        border.color: root.isHighlighted
            ? Colours.palette.m3primary
            : (hoverHandler.hovered ? Colours.palette.m3outline : Colours.palette.m3outlineVariant)

        opacity: dragArea.drag.active ? 0.6 : 1.0

        Behavior on border.color { CAnim {} }
        Behavior on opacity { Anim {} }

        // Live Window Preview + Header clipped cleanly to rounded corners
        ClippingWrapperRectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            radius: Tokens.rounding.small

            Item {
                anchors.fill: parent

                ScreencopyView {
                    id: screencopy
                    anchors.fill: parent
                    captureSource: root.modelData?.wayland ?? null
                    live: true
                    constraintSize.width: Math.max(1, root.targetW)
                    constraintSize.height: Math.max(1, root.targetH)
                    visible: captureSource !== null
                }

                // Top bar overlay on top of the live screencopy
                StyledRect {
                    id: topBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.min(24, Math.max(18, root.height * 0.28))
                    radius: Tokens.rounding.small
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                    opacity: hoverHandler.hovered || screencopy.captureSource === null ? 0.95 : 0.75

                    Behavior on opacity { Anim {} }

                    Row {
                        anchors.left: parent.left
                        anchors.right: closeBtn.visible ? closeBtn.left : parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.extraSmall
                        anchors.rightMargin: Tokens.padding.extraSmall
                        spacing: Tokens.spacing.extraSmall
                        clip: true

                        IconImage {
                            id: icon
                            asynchronous: true
                            source: Icons.getAppIcon(root.ipc.class || root.ipc.initialClass || "", "image-missing")
                            implicitWidth: Math.min(14, topBar.height - 4)
                            implicitHeight: Math.min(14, topBar.height - 4)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            id: titleText
                            text: root.modelData?.title || root.ipc.class || qsTr("Window")
                            font.pixelSize: Math.max(8, Math.min(11, topBar.height * 0.6))
                            font.weight: Font.DemiBold
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            width: parent.width - icon.width - Tokens.spacing.extraSmall
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.width > 55
                        }
                    }

                    // Close button on hover
                    IconButton {
                        id: closeBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 2
                        implicitWidth: Math.min(16, topBar.height - 2)
                        implicitHeight: Math.min(16, topBar.height - 2)
                        icon: "close"
                        visible: hoverHandler.hovered && root.width > 48 && root.height > 24
                        onClicked: OverviewState.closeWindow(root.modelData)
                    }
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            drag.target: root

            drag.onActiveChanged: {
                if (drag.active) {
                    root.parent.parent.Drag.start();
                }
            }

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    OverviewState.closeWindow(root.modelData);
                } else if (mouse.button === Qt.LeftButton) {
                    OverviewState.focusWindow(root.modelData);
                }
            }
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
