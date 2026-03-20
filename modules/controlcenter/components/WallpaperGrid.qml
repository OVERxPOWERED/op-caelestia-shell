pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.config
import QtQuick

GridView {
    id: root

    required property Session session

    readonly property int minCellWidth: 200 + Appearance.spacing.normal
    readonly property int columnsCount: Math.max(1, Math.floor(width / minCellWidth))

    cellWidth: width / columnsCount
    cellHeight: 140 + Appearance.spacing.normal

    model: Wallpapers.list

    clip: true

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    delegate: Item {
        id: wpDelegate

        required property var modelData
        required property int index
        readonly property bool isCurrent: modelData && modelData.path === Wallpapers.actualCurrent
        readonly property real itemMargin: Appearance.spacing.normal / 2
        readonly property real itemRadius: Appearance.rounding.normal

        width: root.cellWidth
        height: root.cellHeight

        StateLayer {
            function onClicked(): void {
                Wallpapers.setWallpaper(wpDelegate.modelData.path);
            }

            anchors.fill: parent
            anchors.leftMargin: wpDelegate.itemMargin
            anchors.rightMargin: wpDelegate.itemMargin
            anchors.topMargin: wpDelegate.itemMargin
            anchors.bottomMargin: wpDelegate.itemMargin
            radius: wpDelegate.itemRadius
        }

        StyledClippingRect {
            id: image

            anchors.fill: parent
            anchors.leftMargin: wpDelegate.itemMargin
            anchors.rightMargin: wpDelegate.itemMargin
            anchors.topMargin: wpDelegate.itemMargin
            anchors.bottomMargin: wpDelegate.itemMargin
            color: Colours.tPalette.m3surfaceContainer
            radius: wpDelegate.itemRadius
            antialiasing: true
            layer.enabled: true
            layer.smooth: true

            CachingImage {
                id: cachingImage

                path: wpDelegate.modelData.path
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: true
                visible: opacity > 0
                antialiasing: true
                smooth: true
                sourceSize: Qt.size(width, height)

                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Fallback if CachingImage fails to load
            Image {
                id: fallbackImage

                anchors.fill: parent
                source: fallbackTimer.triggered && cachingImage.status !== Image.Ready ? wpDelegate.modelData.path : ""
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                cache: true
                visible: opacity > 0
                antialiasing: true
                smooth: true
                sourceSize: Qt.size(width, height)

                opacity: status === Image.Ready && cachingImage.status !== Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Timer {
                id: fallbackTimer

                property bool triggered: false

                interval: 800
                running: cachingImage.status === Image.Loading || cachingImage.status === Image.Null
                onTriggered: triggered = true
            }

            // Gradient overlay for filename
            Rectangle {
                id: filenameOverlay

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                implicitHeight: filenameText.implicitHeight + Appearance.padding.normal * 1.5
                radius: 0

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0)
                    }
                    GradientStop {
                        position: 0.3
                        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.7)
                    }
                    GradientStop {
                        position: 0.6
                        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.9)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.95)
                    }
                }

                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutCubic
                    }
                }

                Component.onCompleted: {
                    opacity = 1;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: wpDelegate.itemMargin
            anchors.rightMargin: wpDelegate.itemMargin
            anchors.topMargin: wpDelegate.itemMargin
            anchors.bottomMargin: wpDelegate.itemMargin
            color: "transparent"
            radius: wpDelegate.itemRadius + border.width
            border.width: wpDelegate.isCurrent ? 2 : 0
            border.color: Colours.palette.m3primary
            antialiasing: true
            smooth: true

            Behavior on border.width {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.padding.small

                visible: wpDelegate.isCurrent
                text: "check_circle"
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.large
            }
        }

        StyledText {
            id: filenameText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
            anchors.rightMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
            anchors.bottomMargin: Appearance.padding.normal

            text: wpDelegate.modelData.name
            font.pointSize: Appearance.font.size.smaller
            font.weight: 500
            color: wpDelegate.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
            elide: Text.ElideMiddle
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter

            opacity: 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 1000
                    easing.type: Easing.OutCubic
                }
            }

            Component.onCompleted: {
                opacity = 1;
            }
        }
    }
}
