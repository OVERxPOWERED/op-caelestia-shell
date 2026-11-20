import QtQuick
import qs.services

/**
 * Analytical SDF directional glass-bevel rim overlay.
 * Default style: Double-Rim + 3px Edge Glow (crisp dual-corner diagonal specular
 * rim, 3px inner refraction glow, and subtle hairline contour).
 */
ShaderEffect {
    id: root

    readonly property bool isLargeSurface: Math.min(width, height) >= 90

    property bool deepBevel: false
    property bool dualRim: false
    property real radius: parent ? (parent.radius ?? 0) : 0
    property real rimWidth: (deepBevel || dualRim) ? 0.90 : 0.65
    property real lightAngle: -2.356
    property real innerSheen: (deepBevel || dualRim) ? 0.16 : (isLargeSurface ? 0.18 : 0.26)
    property real glowWidth: (deepBevel || dualRim) ? 5.0 : 2.5
    property real ambientRim: (deepBevel || dualRim)
        ? (Colours.light ? 0.20 : 0.16)
        : (Colours.light
            ? (isLargeSurface ? 0.24 : 0.14)
            : (isLargeSurface ? 0.22 : 0.08))
    property int mode: dualRim ? 2 : deepBevel ? 1 : 0
    property real lensMix: 0.0
    property real topSheen: deepBevel ? (Colours.light ? 0.04 : 0.06) : 0.0
    property real cornerPower: dualRim ? 1.1 : deepBevel ? 1.25 : (isLargeSurface ? 1.15 : 1.4)
    property real secondaryStrength: dualRim ? 0.92 : deepBevel ? 0.78 : 0.85
    property color highlightColor: {
        if (deepBevel || dualRim) {
            const base = Colours.palette.m3primary;
            const r = Colours.light ? 1.0 : (0.85 + base.r * 0.15);
            const g = Colours.light ? 1.0 : (0.85 + base.g * 0.15);
            const b = Colours.light ? 1.0 : (0.85 + base.b * 0.15);
            return Qt.rgba(r, g, b, Colours.light ? 0.86 : 0.52);
        }
        return Colours.light
            ? Qt.rgba(1.0, 1.0, 1.0, 0.88)
            : Qt.rgba(1.0, 1.0, 1.0, 0.52);
    }
    property color shadowColor: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    property color contourColor: Colours.light
        ? Qt.rgba(0.0, 0.0, 0.0, 0.14)
        : Qt.rgba(0.0, 0.0, 0.0, 0.30)

    // Uniforms mapped 1:1 with glassrim.frag std140 layout
    readonly property real uRadius: radius
    readonly property real uRimWidth: rimWidth
    readonly property real uLightAngle: lightAngle
    readonly property vector2d uSize: Qt.vector2d(width, height)
    readonly property real uInnerSheen: innerSheen
    readonly property real uAmbientRim: ambientRim
    readonly property real uMode: mode
    readonly property real uTopSheen: topSheen
    readonly property real uCornerPower: cornerPower
    readonly property real uSecondaryStrength: secondaryStrength
    readonly property color uHighlightColor: highlightColor
    readonly property color uShadowColor: shadowColor
    readonly property color uContourColor: contourColor
    readonly property real uGlowWidth: glowWidth
    readonly property real uLensMix: lensMix

    anchors.fill: parent
    visible: width > 0 && height > 0

    vertexShader: Qt.resolvedUrl("shaders/glassrim.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/glassrim.frag.qsb")
}
