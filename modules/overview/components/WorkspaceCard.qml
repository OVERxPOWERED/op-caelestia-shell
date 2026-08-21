pragma ComponentBehavior: Bound

import QtQuick
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

    signal clicked

    implicitWidth: baseWidth
    implicitHeight: baseHeight + 36

    scale: hoverHandler.hovered || isSelected ? 1.03 : (isFocused ? 1.01 : 1.0)
    Behavior on scale { Anim {} }

    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: drop => {
            if (drop.source && modelData) {
                OverviewState.moveWindowToWorkspace(drop.source, modelData.id);
            }
        }
    }

    // Top Card Header
    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        // Workspace number badge
        StyledRect {
            implicitWidth: 24
            implicitHeight: 24
            radius: Tokens.rounding.full
            color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
            anchors.verticalCenter: parent.verticalCenter

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
            text: root.modelData?.name ?? qsTr("Workspace")
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3onSurface
            anchors.verticalCenter: parent.verticalCenter
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
            anchors.verticalCenter: parent.verticalCenter

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
            implicitWidth: 1
            implicitHeight: 1
            width: Math.max(1, header.width - (parent.children[0].width + parent.children[1].width + (parent.children[2].visible ? parent.children[2].width : 0) + parent.children[4].width + Tokens.spacing.small * 5))
        }

        // Window count badge
        Row {
            spacing: Tokens.spacing.extraSmall
            anchors.verticalCenter: parent.verticalCenter

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
        border.width: root.isFocused ? 2 : (hoverHandler.hovered || root.isSelected || dropArea.containsDrag ? 1.5 : 1)
        border.color: root.isFocused
            ? Colours.palette.m3primary
            : (dropArea.containsDrag ? Colours.palette.m3tertiary : (hoverHandler.hovered || root.isSelected ? Colours.palette.m3outline : Colours.palette.m3outlineVariant))

        Behavior on border.color { CAnim {} }
        Behavior on border.width { Anim {} }

        // Curved Content Wrapper
        ClippingWrapperRectangle {
            anchors.fill: parent
            anchors.margins: 1
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

                // Miniature windows viewport
                Item {
                    id: innerViewport
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall

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

        // State layer for card clicks
        StateLayer {
            id: stateLayer
            anchors.fill: parent
            radius: Tokens.rounding.large
            onClicked: root.clicked()
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
