import "weather"
import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property int rootHeight // TODO: add forecast when large height

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
    radius: Tokens.rounding.extraExtraLarge
    color: Colours.tPalette.m3surfaceContainer

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }

    BriefInfo {
        id: layout

        anchors.centerIn: parent
    }
}
