pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: parent.width
    implicitHeight: 48

    Row {
        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        // 1. Navigate
        Row {
            spacing: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                text: "open_with"
                fontStyle: Tokens.font.icon.medium
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: qsTr("Navigate")
                font.pixelSize: 12
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 2. Enter: Switch
        Row {
            spacing: Tokens.spacing.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                implicitWidth: enterText.implicitWidth + 14
                implicitHeight: 22
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                StyledText {
                    id: enterText
                    anchors.centerIn: parent
                    text: qsTr("Enter")
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Colours.palette.m3primary
                }
            }

            StyledText {
                text: qsTr("Switch to Workspace")
                font.pixelSize: 12
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 3. Drag Move
        Row {
            spacing: Tokens.spacing.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                implicitWidth: dragKeyText.implicitWidth + 14
                implicitHeight: 22
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                StyledText {
                    id: dragKeyText
                    anchors.centerIn: parent
                    text: qsTr("Drag")
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Colours.palette.m3primary
                }
            }

            StyledText {
                text: qsTr("Move Window")
                font.pixelSize: 12
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 4. Middle Click: Close
        Row {
            spacing: Tokens.spacing.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                implicitWidth: midKeyText.implicitWidth + 14
                implicitHeight: 22
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                StyledText {
                    id: midKeyText
                    anchors.centerIn: parent
                    text: qsTr("Middle Click")
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Colours.palette.m3primary
                }
            }

            StyledText {
                text: qsTr("Close Window")
                font.pixelSize: 12
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 5. 4-Finger Touchpad Gesture
        Row {
            spacing: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                text: "touch_app"
                fontStyle: Tokens.font.icon.medium
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: qsTr("4-Finger Swipe Gesture")
                font.pixelSize: 12
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
