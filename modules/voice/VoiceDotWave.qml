pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

/**
 * Symmetric multi-dot audio waveform indicator.
 * Renders either inside a frosted sub-capsule (Classic theme) or inline (Compact theme).
 */
Item {
    id: root

    property int dotCount: 9
    property bool inCapsule: true
    property bool active: true
    property bool paused: false
    property bool animate: true
    property bool previewMode: false
    property real speedFactor: 1.0
    property var barLevels: [0.0, 0.0, 0.0, 0.0]
    property color dotColor: Colours.palette.m3onSurfaceVariant
    property color activeColor: Colours.palette.m3primary
    property real dotSize: 3.0
    property real dotSpacing: 3.0
    property real maxDotHeight: 16.0

    readonly property real rowWidth: dotCount * dotSize + Math.max(0, dotCount - 1) * dotSpacing

    implicitWidth: inCapsule ? rowWidth + 16 : rowWidth
    implicitHeight: inCapsule ? 28 : 20

    StyledRect {
        anchors.fill: parent
        visible: root.inCapsule
        radius: height / 2
        color: Colours.transparency.enabled
            ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.55)
            : Colours.palette.m3surfaceContainerHighest
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
        border.width: 1
    }

    Row {
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.dotCount

            Rectangle {
                id: dot

                required property int index

                readonly property real centerNorm: {
                    const mid = (root.dotCount - 1) / 2.0;
                    const dist = mid > 0 ? Math.abs(index - mid) / mid : 0.0;
                    return 1.0 - dist * 0.65;
                }

                readonly property real bandValue: {
                    if (root.previewMode) {
                        const mid = (root.dotCount - 1) / 2.0;
                        const dist = mid > 0 ? Math.abs(index - mid) / mid : 0.0;
                        return (index % 2 === 0 ? 0.55 : 0.25) * (1.0 - dist * 0.5);
                    }
                    if (!root.barLevels || root.barLevels.length === 0)
                        return 0.0;
                    const mapped = Math.min(root.barLevels.length - 1, Math.floor((index / root.dotCount) * root.barLevels.length));
                    const v = root.barLevels[mapped] || 0.0;
                    const waveRipple = root.animate
                        ? 0.82 + 0.18 * Math.sin(VoiceTyping.wavePhase * 1.5 + index * 0.85)
                        : 1.0;
                    return v * centerNorm * waveRipple;
                }

                readonly property real targetHeight: {
                    if (!root.active)
                        return root.dotSize;
                    if (root.paused)
                        return (index === Math.floor(root.dotCount / 2)) ? root.dotSize * 2.2 : root.dotSize;
                    return Math.min(root.maxDotHeight, Math.max(root.dotSize, root.dotSize + bandValue * (root.maxDotHeight - root.dotSize)));
                }

                width: root.dotSize
                height: targetHeight
                radius: root.dotSize / 2
                anchors.verticalCenter: parent.verticalCenter
                color: (bandValue > 0.15 && !root.paused)
                    ? Qt.tint(root.dotColor, Qt.alpha(root.activeColor, Math.min(0.85, bandValue * 0.9)))
                    : root.dotColor
                opacity: root.paused ? 0.5 : (0.55 + Math.min(0.45, bandValue * 0.6))

                Behavior on height {
                    enabled: root.animate
                    NumberAnimation {
                        duration: Math.max(30, Math.round((root.paused ? 160 : 55) / root.speedFactor))
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
