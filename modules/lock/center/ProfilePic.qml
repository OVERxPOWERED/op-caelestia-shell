import QtQuick
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.utils

StyledClippingRect {
    id: root

    required property int centerWidth

    implicitWidth: centerWidth / 2
    implicitHeight: centerWidth / 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    MaterialIcon {
        anchors.centerIn: parent

        text: "person"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size(root.centerWidth / 4).build()
        visible: pfp.status !== Image.Ready
    }

    CachingImage {
        id: pfp

        anchors.fill: parent
        path: `${Paths.home}/.face`
    }
}
