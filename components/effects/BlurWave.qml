import QtQuick
import QtQuick.Effects
import Caelestia.Config
import qs.services

Item {
    id: root

    required property Item target
    required property bool active

    // Tunable wave parameters
    property string direction: "topToBottom" // "topToBottom" | "bottomToTop" | "leftToRight" | "rightToLeft"
    property real waveHeight: 0.45           // Tall wave span as a fraction of panel size
    property int blurLayers: 6               // Number of gradual blur steps across the wave
    property int duration: 800               // Wave sweep duration in ms
    property int easingType: Easing.OutCubic // Easing curve for waveProgress
    property real blurStrength: 1.0          // 0.0 .. 1.0
    property int blurMax: 32                 // Max blur radius in px
    property real cornerRadius: Config.border.rounding

    property real waveProgress: (active && !GameMode.enabled) ? 0 : 1
    readonly property bool targetReady: target.width > 0 && target.height > 0
        && (target.status === undefined || target.status === Loader.Ready)
    readonly property bool waveActive: !GameMode.enabled && active && waveProgress < 1 && targetReady

    readonly property bool isHorizontal: direction === "leftToRight" || direction === "rightToLeft"
    readonly property bool isReversed: direction === "bottomToTop" || direction === "rightToLeft"

    readonly property real totalSpan: isHorizontal ? width : height
    readonly property real bandSpan: totalSpan * Math.max(0.01, waveHeight)
    readonly property real waveHead: waveProgress * (totalSpan + bandSpan) - bandSpan

    function bandStart(layerIndex: int): int {
        const raw = layerIndex < 0 ? 0 : waveHead + (layerIndex / blurLayers) * bandSpan;
        return Math.max(0, Math.min(Math.round(totalSpan), Math.round(raw)));
    }

    function bandEnd(layerIndex: int): int {
        if (layerIndex >= blurLayers - 1)
            return Math.round(totalSpan);
        const raw = waveHead + ((layerIndex + 1) / blurLayers) * bandSpan;
        return Math.max(0, Math.min(Math.round(totalSpan), Math.round(raw)));
    }

    anchors.fill: target
    visible: waveActive

    NumberAnimation {
        id: waveAnim
        target: root
        property: "waveProgress"
        from: 0
        to: 1
        duration: root.duration
        easing.type: root.easingType
    }

    onActiveChanged: {
        if (active && !GameMode.enabled) {
            waveProgress = 0;
            waveAnim.restart();
        } else {
            waveAnim.stop();
            waveProgress = 1;
        }
    }

    onTargetReadyChanged: {
        if (targetReady && active && !GameMode.enabled) {
            waveProgress = 0;
            waveAnim.restart();
        }
    }

    Component.onCompleted: {
        if (active && !GameMode.enabled) {
            waveProgress = 0;
            waveAnim.restart();
        }
    }

    Connections {
        target: GameMode
        function onEnabledChanged() {
            if (GameMode.enabled) {
                waveAnim.stop();
                root.waveProgress = 1;
            }
        }
    }

    ShaderEffectSource {
        id: panelCapture
        sourceItem: root.waveActive ? root.target : null
        live: root.waveActive
        hideSource: root.waveActive
        visible: false
    }

    Rectangle {
        id: roundedMask
        width: root.width
        height: root.height
        radius: root.cornerRadius
        color: "white"
        visible: false
    }

    ShaderEffectSource {
        id: roundedMaskSource
        sourceItem: roundedMask
        live: true
        visible: false
    }

    // Sharp region (already swept by the wave)
    Item {
        id: sharpRegion
        clip: true

        readonly property int s: 0
        readonly property int e: Math.max(0, Math.min(Math.round(root.totalSpan), Math.round(root.waveHead)))
        readonly property int pos: root.isReversed ? Math.round(root.totalSpan) - e : s
        readonly property int len: Math.max(0, e - s)

        x: root.isHorizontal ? pos : 0
        y: root.isHorizontal ? 0 : pos
        width: root.isHorizontal ? len : parent.width
        height: root.isHorizontal ? parent.height : len

        ShaderEffectSource {
            x: -sharpRegion.x
            y: -sharpRegion.y
            width: root.target.width
            height: root.target.height
            sourceItem: root.waveActive ? root.target : null
            live: root.waveActive
        }
    }

    // Multi-layer gradual blur wave, masked to dashboard corners
    Item {
        id: blurContainer
        anchors.fill: parent

        layer.enabled: root.waveActive && root.cornerRadius > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundedMaskSource
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Repeater {
            model: root.blurLayers

            delegate: Item {
                id: blurStrip

                required property int index

                readonly property int s: root.bandStart(index)
                readonly property int e: Math.max(s, root.bandEnd(index))
                readonly property int pos: root.isReversed ? Math.round(root.totalSpan) - e : s
                readonly property int len: Math.max(0, e - s)
                readonly property real level: (index + 1) / root.blurLayers

                clip: true
                visible: len > 0

                x: root.isHorizontal ? pos : 0
                y: root.isHorizontal ? 0 : pos
                width: root.isHorizontal ? len : parent.width
                height: root.isHorizontal ? parent.height : len

                MultiEffect {
                    x: -blurStrip.x
                    y: -blurStrip.y
                    width: root.target.width
                    height: root.target.height
                    source: panelCapture
                    blurEnabled: true
                    blur: root.blurStrength * blurStrip.level
                    blurMax: root.blurMax
                    autoPaddingEnabled: false
                }
            }
        }
    }
}
