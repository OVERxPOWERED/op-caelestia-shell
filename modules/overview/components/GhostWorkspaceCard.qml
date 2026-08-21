pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import ".."

Item {
    id: root

    property real baseWidth: 200
    property real baseHeight: 400 * (9 / 16)

    signal clicked

    implicitWidth: baseWidth
    implicitHeight: baseHeight + 56

    scale: hoverHandler.hovered ? 1.03 : 1.0
    Behavior on scale { Anim {} }

    StyledRect {
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.baseHeight
        radius: Tokens.rounding.large

        color: hoverHandler.hovered ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 1) : Colours.layer(Colours.palette.m3surfaceContainerLow, 0)
        border.width: 1.5
        border.color: hoverHandler.hovered ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

        Behavior on color { CAnim {} }
        Behavior on border.color { CAnim {} }

        Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledRect {
                implicitWidth: 44
                implicitHeight: 44
                radius: Tokens.rounding.full
                color: hoverHandler.hovered ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
                anchors.horizontalCenter: parent.horizontalCenter

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    fontStyle: Tokens.font.icon.large
                    color: hoverHandler.hovered ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                }
            }

            StyledText {
                text: qsTr("New Workspace")
                font.pixelSize: 12
                font.weight: Font.Medium
                color: hoverHandler.hovered ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        StateLayer {
            anchors.fill: parent
            radius: Tokens.rounding.large
            onClicked: root.clicked()
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
