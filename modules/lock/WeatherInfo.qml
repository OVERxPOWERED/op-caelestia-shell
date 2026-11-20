import "weather"
import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property int rootHeight
    property Item blurSource: null
    property real absX: 0
    property real absY: 0
    property bool compact: false
    property bool borderless: false
    readonly property bool showForecast: !compact && rootHeight >= Tokens.sizes.lock.showForecastHeight

    implicitHeight: {
        const base = brief.implicitHeight + brief.anchors.topMargin;
        if (showForecast)
            return base + Tokens.spacing.largeIncreased + forecast.implicitHeight + forecast.anchors.margins;
        return base + Tokens.padding.large;
    }
    radius: Tokens.rounding.extraExtraLarge
    color: Config.lock.useLegacyLayout ? Colours.tPalette.m3surfaceContainer : "transparent"
    antialiasing: true

    GlassBackdrop {
        visible: !Config.lock.useLegacyLayout && !root.borderless && root.blurSource !== null
        blurSource: root.blurSource
        absX: root.absX
        absY: root.absY
        radius: root.radius
    }

    GlassRim {
        z: 10
        visible: !root.borderless
        radius: root.radius
        deepBevel: Config.lock.useLegacyLayout
        dualRim: !Config.lock.useLegacyLayout
    }

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }

    BriefInfo {
        id: brief

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.large

        rootHeight: root.rootHeight
    }

    Loader {
        id: forecast

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        active: root.showForecast
        asynchronous: true

        sourceComponent: Forecast {}
    }
}
