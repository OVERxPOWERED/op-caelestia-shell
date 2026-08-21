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

    required property HyprlandMonitor monitor
    signal closeRequested

    readonly property var toplevels: OverviewState.getAllToplevels("")
    readonly property real cardWidth: 300
    readonly property real cardHeight: 180

    implicitWidth: parent.width
    implicitHeight: 400

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: Math.max(width, grid.implicitWidth + Tokens.padding.large * 2)
        contentHeight: Math.max(height, grid.implicitHeight + Tokens.padding.large * 2)
        clip: false
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: container
            width: flickable.contentWidth
            height: flickable.contentHeight

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: Math.max(1, Math.min(4, Math.floor((flickable.width - Tokens.padding.large * 2) / (root.cardWidth + Tokens.spacing.large))))
                spacing: Tokens.spacing.large

                Repeater {
                    model: root.toplevels

                    StyledRect {
                        id: itemCard
                        required property HyprlandToplevel modelData
                        required property int index

                        readonly property var ipc: this.modelData?.lastIpcObject ?? ({})
                        readonly property bool isFocused: Hypr.activeToplevel?.address === this.modelData?.address

                        implicitWidth: root.cardWidth
                        implicitHeight: root.cardHeight
                        radius: Tokens.rounding.large

                        color: hoverHandler.hovered ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 1) : Colours.layer(Colours.palette.m3surfaceContainer, 0)
                        border.width: isFocused ? 2 : 1
                        border.color: isFocused ? Colours.palette.m3primary : (hoverHandler.hovered ? Colours.palette.m3outline : Colours.palette.m3outlineVariant)

                        scale: hoverHandler.hovered ? 1.02 : 1.0
                        Behavior on scale { Anim {} }
                        Behavior on color { CAnim {} }
                        Behavior on border.color { CAnim {} }

                        // Clipped window content
                        ClippingWrapperRectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            color: "transparent"
                            radius: Tokens.rounding.large

                            Item {
                                anchors.fill: parent

                                // Live Wayland Screencopy preview of the window
                                ScreencopyView {
                                    id: screencopy
                                    anchors.fill: parent
                                    captureSource: itemCard.modelData?.wayland ?? null
                                    live: true
                                    constraintSize.width: root.cardWidth
                                    constraintSize.height: root.cardHeight
                                    visible: captureSource !== null
                                }

                                // Top Bar Header Overlay
                                StyledRect {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 34
                                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                                    opacity: hoverHandler.hovered || screencopy.captureSource === null ? 0.95 : 0.8

                                    Behavior on opacity { Anim {} }

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.extraSmall
                                        spacing: Tokens.spacing.small

                                        IconImage {
                                            asynchronous: true
                                            source: Icons.getAppIcon(itemCard.ipc.class || itemCard.ipc.initialClass || "", "image-missing")
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: itemCard.modelData?.title || itemCard.ipc.class || qsTr("Window")
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Colours.palette.m3onSurface
                                            elide: Text.ElideRight
                                            width: parent.width - 20 - 24 - Tokens.spacing.small * 2
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        IconButton {
                                            icon: "close"
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            onClicked: OverviewState.closeWindow(itemCard.modelData)
                                        }
                                    }
                                }

                                // Bottom Workspace Pill
                                StyledRect {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.margins: Tokens.padding.small
                                    implicitWidth: wsText.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: Tokens.rounding.full
                                    color: itemCard.isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                                    opacity: 0.95

                                    StyledText {
                                        id: wsText
                                        anchors.centerIn: parent
                                        text: itemCard.modelData?.workspace?.name ?? qsTr("WS")
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: itemCard.isFocused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            onClicked: {
                                OverviewState.focusWindow(itemCard.modelData, () => root.closeRequested());
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.MiddleButton
                            onClicked: OverviewState.closeWindow(itemCard.modelData)
                        }

                        HoverHandler {
                            id: hoverHandler
                        }
                    }
                }
            }
        }
    }

    // Empty state when no windows are open
    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.small
        visible: root.toplevels.length === 0

        MaterialIcon {
            text: "grid_view"
            fontStyle: Tokens.font.icon.extraLarge
            color: Colours.palette.m3onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: qsTr("No active windows open")
            font.pixelSize: 14
            color: Colours.palette.m3onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
