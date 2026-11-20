import QtQuick
import QtQuick.Effects
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property Item blurSource
    required property real absX
    required property real absY
    property real tintOpacity: 0.2

    anchors.fill: parent
    color: "transparent"
    visible: blurSource !== null && width > 0 && height > 0

    MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        blurMultiplier: 1.2

        source: ShaderEffectSource {
            sourceItem: root.blurSource
            sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Colours.palette.m3surface, root.tintOpacity)
    }
}
