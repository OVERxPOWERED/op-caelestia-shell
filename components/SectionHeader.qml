import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import Caelestia.Config

ColumnLayout {
    id: root

    required property string title
    property string description: ""

    spacing: 0

    StyledText {
        Layout.topMargin: Tokens.spacing.large
        text: root.title
        font.pointSize: Tokens.font.size.larger
        font.weight: 500
    }

    StyledText {
        visible: root.description !== ""
        text: root.description
        color: Colours.palette.m3outline
    }
}
