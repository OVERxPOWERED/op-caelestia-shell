pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import qs.components
import qs.services

Item {
    id: root

    clip: true

    // Total shapes in the heap
    readonly property int count: 38

    readonly property list<int> shapePool: [
        MaterialShape.Circle,
        MaterialShape.Cookie4Sided,
        MaterialShape.Cookie6Sided,
        MaterialShape.Sunny,
        MaterialShape.VerySunny,
        MaterialShape.SoftBurst,
        MaterialShape.Pentagon,
        MaterialShape.Gem,
        MaterialShape.Arch,
        MaterialShape.Arrow,
        MaterialShape.Pill,
        MaterialShape.Triangle,
        MaterialShape.Diamond,
        MaterialShape.Clover4Leaf,
        MaterialShape.Heart
    ]

    property real idlePhase: 0.0

    Timer {
        interval: 60
        repeat: true
        running: Pomodoro.running && root.visible
        onTriggered: root.idlePhase = (root.idlePhase + 0.06) % (Math.PI * 2)
    }

    // Precalculated deterministic layout model
    readonly property var shapeDataList: {
        const list = [];
        const poolLen = root.shapePool.length;
        for (let i = 0; i < root.count; i++) {
            // Distribute normY smoothly from 0.04 (bottom) to 0.92 (top) with subtle organic jitter
            const jitter = Math.sin(i * 3.7) * 0.035;
            const normY = Math.min(0.92, Math.max(0.04, (i + 0.5) / root.count + jitter));

            // Distribute normX across card width (0.06 to 0.82)
            const normX = 0.06 + (((i * 0.6180339887) % 1.0) * 0.76);

            const shapeIndex = Math.abs(Math.floor(Math.sin(i * 5.1) * poolLen)) % poolLen;
            const size = 12.5 + (Math.abs(Math.sin(i * 2.3)) * 4.5); // 12.5px - 17px
            const rot = (i * 53) % 360;
            const colorIdx = i % 4;
            const opacityBase = 0.44 + (Math.abs(Math.cos(i * 1.9)) * 0.22); // 0.44 - 0.66

            list.push({
                index: i,
                normX: normX,
                normY: normY,
                shapeType: root.shapePool[shapeIndex],
                size: size,
                rot: rot,
                colorIdx: colorIdx,
                opacityBase: opacityBase
            });
        }
        return list;
    }

    Repeater {
        id: shapesRepeater
        model: root.shapeDataList

        Item {
            id: shapeContainer

            required property var modelData
            required property int index

            readonly property real sSize: modelData.size
            readonly property bool isSpawned: Pomodoro.progress >= modelData.normY && Pomodoro.timeRemaining < Pomodoro.totalTime

            readonly property real targetY: Math.round((1.0 - modelData.normY) * (root.height - sSize))
            readonly property real startY: -sSize - 16

            x: Math.round(modelData.normX * (root.width - sSize))
            y: isSpawned ? targetY : startY
            width: sSize
            height: sSize

            scale: isSpawned ? 1.0 : 0.3
            opacity: isSpawned ? modelData.opacityBase : 0.0

            Behavior on y {
                NumberAnimation {
                    duration: shapeContainer.isSpawned ? 650 : 200
                    easing.type: shapeContainer.isSpawned ? Easing.OutBounce : Easing.InQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: shapeContainer.isSpawned ? 400 : 200
                    easing.type: shapeContainer.isSpawned ? Easing.OutBack : Easing.InQuad
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: shapeContainer.isSpawned ? 260 : 180
                }
            }

            MaterialShape {
                id: shapeGraphic

                anchors.centerIn: parent
                implicitSize: shapeContainer.sSize
                shape: shapeContainer.modelData.shapeType
                color: root.getShapeColor(shapeContainer.modelData.colorIdx)

                readonly property real wobble: Pomodoro.running ? Math.sin(root.idlePhase + shapeContainer.index * 0.7) * 4.0 : 0.0
                rotation: shapeContainer.isSpawned ? (shapeContainer.modelData.rot + wobble) : (shapeContainer.modelData.rot - 120)

                Behavior on rotation {
                    NumberAnimation {
                        duration: 650
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    function getShapeColor(colorIdx: int): color {
        switch (Pomodoro.mode) {
        case Pomodoro.Mode.ShortBreak:
            return [
                Colours.palette.m3tertiary,
                Colours.palette.m3tertiaryContainer,
                Colours.palette.m3secondary,
                Colours.palette.m3outlineVariant
            ][colorIdx];
        case Pomodoro.Mode.LongBreak:
            return [
                Colours.palette.m3secondary,
                Colours.palette.m3secondaryContainer,
                Colours.palette.m3primary,
                Colours.palette.m3outlineVariant
            ][colorIdx];
        default: // Focus
            return [
                Colours.palette.m3primary,
                Colours.palette.m3primaryContainer,
                Colours.palette.m3secondary,
                Colours.palette.m3tertiaryContainer
            ][colorIdx];
        }
    }
}
