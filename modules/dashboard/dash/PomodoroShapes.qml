pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.widgets
import qs.services

StyledClippingRect {
    id: root

    required property color accentColour
    property real animProgress: FocusTimer.progress
    property real waveAmp: FocusTimer.running ? 4.5 : 1.5
    property real backWaveX: -width
    property real frontWaveX: 0

    radius: Tokens.rounding.medium
    color: Qt.alpha(root.accentColour, 0.06)

    Behavior on animProgress {
        Anim {}
    }

    Behavior on waveAmp {
        Anim {
            type: Anim.FastEffects
        }
    }

    Behavior on color {
        CAnim {}
    }

    NumberAnimation {
        target: root
        property: "backWaveX"
        from: -root.width
        to: 0
        duration: 4600
        loops: Animation.Infinite
        running: FocusTimer.running && root.visible && root.width > 0 && root.animProgress > 0.0001
    }

    NumberAnimation {
        target: root
        property: "frontWaveX"
        from: 0
        to: -root.width
        duration: 3200
        loops: Animation.Infinite
        running: FocusTimer.running && root.visible && root.width > 0 && root.animProgress > 0.0001
    }

    // Back wave layer
    WavyTopRect {
        id: backWave

        readonly property real fillH: root.animProgress <= 0.0001 ? 0 : (root.height + amplitude * 2) * root.animProgress

        x: root.backWaveX
        y: root.height - fillH
        width: root.width * 2
        height: Math.max(0, fillH + root.waveAmp * 2)
        waves: 4
        amplitude: root.waveAmp * 0.85
        color: Qt.alpha(root.accentColour, 0.16)
        visible: root.animProgress > 0.0001 && root.width > 0
    }

    // Front wave layer
    WavyTopRect {
        id: frontWave

        readonly property real fillH: root.animProgress <= 0.0001 ? 0 : (root.height + amplitude * 2) * root.animProgress

        x: root.frontWaveX
        y: root.height - fillH + 2
        width: root.width * 2
        height: Math.max(0, fillH + root.waveAmp * 2)
        waves: 4
        amplitude: root.waveAmp
        color: Qt.alpha(root.accentColour, 0.26)
        visible: root.animProgress > 0.0001 && root.width > 0
    }
}
