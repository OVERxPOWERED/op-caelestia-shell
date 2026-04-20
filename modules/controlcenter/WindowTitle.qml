import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitHeight: text.implicitHeight + Tokens.padding.medium
    color: Colours.tPalette.m3surfaceContainer

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        text: qsTr("Caelestia Settings - %1").arg(root.session.active)
        font.capitalization: Font.Capitalize
        font.pointSize: Tokens.font.size.larger
        font.weight: 500
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium

        implicitWidth: implicitHeight
        implicitHeight: closeIcon.implicitHeight + Tokens.padding.extraSmall

        StateLayer {
            onClicked: {
                QsWindow.window.destroy();
            }

            radius: Tokens.rounding.full
        }

        MaterialIcon {
            id: closeIcon

            anchors.centerIn: parent
            text: "close"
        }
    }
}
