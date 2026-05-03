import QtQuick
import QtQuick.Templates
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    property bool wavy: true
    property bool animateWave
    property alias waveFrequency: wave.frequency
    property alias waveDuration: waveAnim.duration

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition

    signal interaction(v: real)

    implicitWidth: 200
    implicitHeight: 12

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: Math.min(width, parent.height)
            opacity: implicitHeight / parent.height

            radius: Tokens.rounding.full
            topLeftRadius: Tokens.rounding.extraSmall / 2
            bottomLeftRadius: Tokens.rounding.extraSmall / 2
            color: root.bgColour
        }

        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (parent.height - implicitHeight) / 2 * remaining.opacity

            implicitWidth: implicitHeight
            implicitHeight: 4 * remaining.opacity
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle

            anchors.left: wave.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitWidth: 4
            implicitHeight: parent.height * (mouse.pressed ? 4 : 3)

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        WavyLine {
            id: wave

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: lineWidth * amplitudeMultiplier * 2 + lineWidth

            lineWidth: parent.height * (root.wavy ? 0.7 : 1)
            amplitudeMultiplier: root.wavy ? 0.5 : 0
            startX: x
            fullLength: parent.width - handle.implicitWidth - handle.anchors.leftMargin
            color: root.fgColour

            Component.onCompleted: implicitWidth = Qt.binding(() => fullLength * root.pos)

            Anim on waveProgress {
                id: waveAnim

                running: true
                paused: !root.animateWave
                from: 0
                to: 1
                duration: 1000
                easing.type: Easing.Linear
                loops: Animation.Infinite
            }

            Behavior on amplitudeMultiplier {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on color {
                CAnim {}
            }

            Behavior on implicitWidth {
                id: widthBehavior

                Anim {}
            }
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: CUtils.clamp(mouse.pressStartPos + mouse.dragMovement, 0, 1)
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handle.implicitHeight

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => dragMovement = (e.x - pressStartX) / width
        onReleased: e => {
            root.interaction(posBinding.value);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }
}
