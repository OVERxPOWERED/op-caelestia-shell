pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

/**
 * Layered floating sine-wave audio ribbons radiating symmetrically from a central badge.
 * Used by the Dynamic Wave voice typing theme and its settings preview card.
 */
Canvas {
    id: root

    property bool active: true
    property bool paused: false
    property bool done: false
    property bool animate: true
    property bool previewMode: false
    property real speedFactor: 1.0
    property real audioLevel: 0.0
    property var barLevels: [0.0, 0.0, 0.0, 0.0]
    property real centerHoleRadius: 20
    property color primaryColor: Colours.palette.m3primary
    property color secondaryColor: Colours.palette.m3onSurface

    // Internal smoothed animation state
    property real phase: 0.0
    property real smoothEnergy: previewMode ? 0.55 : 0.0
    property real envelopeScale: (active && !done) ? 1.0 : 0.0

    Behavior on envelopeScale {
        NumberAnimation {
            duration: root.animate ? Math.max(120, Math.round(240 / root.speedFactor)) : 0
            easing.type: Easing.OutCubic
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onEnvelopeScaleChanged: requestPaint()
    onPrimaryColorChanged: requestPaint()
    onSecondaryColorChanged: requestPaint()
    onPreviewModeChanged: requestPaint()

    Component.onCompleted: requestPaint()

    FrameAnimation {
        running: root.visible && root.active && !root.done && !root.previewMode && root.animate
        onTriggered: {
            const dt = Math.min(0.05, Math.max(0.004, frameTime));
            const target = root.paused
                ? 0.04
                : Math.min(1.0, Math.max(0.14, root.audioLevel * 1.45));
            const lerpRate = target > root.smoothEnergy ? 14.0 : 7.5;
            root.smoothEnergy += (target - root.smoothEnergy) * Math.min(1.0, dt * lerpRate);
            root.phase += dt * (2.6 + root.smoothEnergy * 3.8) * root.speedFactor;
            root.requestPaint();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        const scale = previewMode ? 1.0 : envelopeScale;
        if (width <= 4 || height <= 4 || scale <= 0.01)
            return;

        const cy = height * 0.5;
        const cx = width * 0.5;
        const halfSpan = Math.max(10, cx - centerHoleRadius * 0.65);
        const maxAmp = (height * 0.42) * scale;
        const energy = previewMode ? 0.58 : smoothEnergy;
        const b0 = (barLevels && barLevels.length > 0) ? barLevels[0] : energy;
        const b1 = (barLevels && barLevels.length > 1) ? barLevels[1] : energy;
        const b2 = (barLevels && barLevels.length > 2) ? barLevels[2] : energy;

        const layers = [
            { freq: 2.1, speed: 1.0, amp: 0.95, phaseOffset: 0.0, alphaFill: 0.14, alphaStroke: 0.72, strokeWidth: previewMode ? 1.2 : 1.8, usePrimary: false },
            { freq: 2.8, speed: -1.25, amp: 0.76, phaseOffset: 1.7, alphaFill: 0.12, alphaStroke: 0.52, strokeWidth: previewMode ? 1.0 : 1.5, usePrimary: true },
            { freq: 3.4, speed: 0.75, amp: 0.54, phaseOffset: 3.1, alphaFill: 0.08, alphaStroke: 0.34, strokeWidth: previewMode ? 0.85 : 1.2, usePrimary: false }
        ];

        const steps = previewMode ? 36 : 52;

        for (let l = 0; l < layers.length; l++) {
            const layer = layers[l];
            const bandBoost = l === 0 ? b1 : (l === 1 ? b0 : b2);
            const effectiveEnergy = previewMode
                ? 0.58
                : Math.min(1.0, energy * 0.7 + bandBoost * 0.5);
            const layerAmp = maxAmp * layer.amp * (0.20 + effectiveEnergy * 0.80);
            const baseColor = layer.usePrimary ? primaryColor : secondaryColor;

            // Draw symmetric left (-1) and right (+1) ribbons
            for (const dir of [-1, 1]) {
                const startX = cx + dir * (centerHoleRadius * 0.55);
                const endX = cx + dir * (centerHoleRadius * 0.55 + halfSpan);

                // Smooth gradient fading cleanly at outer tip and near center badge
                const grad = ctx.createLinearGradient(startX, cy, endX, cy);
                grad.addColorStop(0.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.25 * scale));
                grad.addColorStop(0.18, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, layer.alphaStroke * scale));
                grad.addColorStop(0.75, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, layer.alphaStroke * 0.65 * scale));
                grad.addColorStop(1.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0));

                const fillGrad = ctx.createLinearGradient(startX, cy, endX, cy);
                fillGrad.addColorStop(0.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.04 * scale));
                fillGrad.addColorStop(0.25, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, layer.alphaFill * scale));
                fillGrad.addColorStop(0.8, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, layer.alphaFill * 0.4 * scale));
                fillGrad.addColorStop(1.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0));

                // Top and bottom mirrored ribbon envelope
                const ptsTop = [];
                const ptsBot = [];
                for (let i = 0; i <= steps; i++) {
                    const u = i / steps;
                    const x = startX + (endX - startX) * u;
                    // Raised-sine taper: 0 at u=0 and u=1, smooth bell in middle
                    const taper = Math.pow(Math.sin(Math.PI * u), 1.35);
                    const p = phase * layer.speed + layer.phaseOffset;
                    const wave = Math.sin(u * Math.PI * layer.freq * 2.0 - p * dir)
                        + 0.35 * Math.sin(u * Math.PI * (layer.freq * 1.7) + p * 0.8);
                    const dy = wave * 0.74 * layerAmp * taper;
                    ptsTop.push({ x: x, y: cy + dy });
                    ptsBot.push({ x: x, y: cy - dy * 0.68 });
                }

                // Soft translucent ribbon fill between primary & mirrored curves
                ctx.beginPath();
                ctx.moveTo(ptsTop[0].x, ptsTop[0].y);
                for (let i = 1; i < ptsTop.length; i++)
                    ctx.lineTo(ptsTop[i].x, ptsTop[i].y);
                for (let i = ptsBot.length - 1; i >= 0; i--)
                    ctx.lineTo(ptsBot[i].x, ptsBot[i].y);
                ctx.closePath();
                ctx.fillStyle = fillGrad;
                ctx.fill();

                // Crisp luminous ribbon stroke
                ctx.beginPath();
                ctx.moveTo(ptsTop[0].x, ptsTop[0].y);
                for (let i = 1; i < ptsTop.length; i++)
                    ctx.lineTo(ptsTop[i].x, ptsTop[i].y);
                ctx.strokeStyle = grad;
                ctx.lineWidth = layer.strokeWidth;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }
}
