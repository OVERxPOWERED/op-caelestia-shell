pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

Item {
    id: root

    required property string icon
    required property string title

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            fontStyle: Tokens.font.icon.builder.size(84).weight(Font.Bold).build()
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
        }
    }
}
