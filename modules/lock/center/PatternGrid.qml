pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property var selectedNodes: []
    property int activeMask: 0
    property bool isDragging: false
    property bool isError: false
    property real currentMx: 0
    property real currentMy: 0

    readonly property real gridSize: Math.min(width, height)
    readonly property real nodeRadius: Math.max(7, gridSize * 0.060)
    readonly property real hitRadius: Math.max(24, gridSize * 0.11)

    signal patternFinished(string code)

    implicitWidth: 230
    implicitHeight: implicitWidth

    function getCenterX(idx: int): real {
        return (gridSize * 0.36) * (idx % 3) + (gridSize * 0.14);
    }

    function getCenterY(idx: int): real {
        return (gridSize * 0.36) * Math.floor(idx / 3) + (gridSize * 0.14);
    }

    function isSelected(idx: int): bool {
        return (activeMask & (1 << idx)) !== 0;
    }

    function checkHit(x: real, y: real): void {
        for (let i = 0; i < 9; i++) {
            if (isSelected(i))
                continue;

            const dx = x - getCenterX(i);
            const dy = y - getCenterY(i);
            if (Math.sqrt(dx * dx + dy * dy) > hitRadius)
                continue;

            const nextNodes = selectedNodes.slice();
            nextNodes.push(i);
            selectedNodes = nextNodes;
            activeMask |= 1 << i;
            canvas.requestPaint();
            return;
        }
    }

    function clearPattern(): void {
        selectedNodes = [];
        activeMask = 0;
        isError = false;
        canvas.requestPaint();
    }

    function triggerError(): void {
        isError = true;
        canvas.requestPaint();
        resetTimer.restart();
    }

    Timer {
        id: resetTimer

        interval: 850
        onTriggered: root.clearPattern()
    }

    Repeater {
        model: 9

        StyledRect {
            required property int index

            readonly property bool active: root.isSelected(index)

            x: root.getCenterX(index) - width / 2
            y: root.getCenterY(index) - height / 2
            implicitWidth: root.nodeRadius * 2
            implicitHeight: implicitWidth
            radius: width / 2
            color: active ? root.isError ? Colours.palette.m3error : Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            scale: active ? 1.6 : 1

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (root.selectedNodes.length === 0)
                return;

            ctx.lineWidth = Math.max(3, root.gridSize * 0.018);
            ctx.strokeStyle = root.isError ? Colours.palette.m3error : Colours.palette.m3primary;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            ctx.beginPath();
            const firstNode = root.selectedNodes[0];
            ctx.moveTo(root.getCenterX(firstNode), root.getCenterY(firstNode));

            for (let i = 1; i < root.selectedNodes.length; i++) {
                const node = root.selectedNodes[i];
                ctx.lineTo(root.getCenterX(node), root.getCenterY(node));
            }

            if (root.isDragging && !root.isError)
                ctx.lineTo(root.currentMx, root.currentMy);

            ctx.stroke();
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        onPressed: mouse => {
            resetTimer.stop();
            root.clearPattern();
            root.isDragging = true;
            root.currentMx = mouse.x;
            root.currentMy = mouse.y;
            root.checkHit(mouse.x, mouse.y);
            canvas.requestPaint();
        }

        onPositionChanged: mouse => {
            if (!root.isDragging)
                return;

            root.currentMx = mouse.x;
            root.currentMy = mouse.y;
            root.checkHit(mouse.x, mouse.y);
            canvas.requestPaint();
        }

        onReleased: {
            root.isDragging = false;
            canvas.requestPaint();

            if (root.selectedNodes.length > 0)
                root.patternFinished(root.selectedNodes.map(n => n + 1).join(""));
        }
    }
}
