pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Draggable map of the enabled displays. Dragging snaps to the edges of other
// displays and refuses to overlap them.
Item {
    id: root

    required property var monitors
    property string selected

    // Layout pixels of free space kept around the displays so they can be dragged apart
    readonly property int margin: 600
    readonly property var shown: monitors.filter(m => !m.disabled && !m.mirrorOf)
    readonly property var mirrored: monitors.filter(m => !m.disabled && m.mirrorOf)

    readonly property var bounds: {
        if (shown.length === 0)
            return {
                x: 0,
                y: 0,
                w: 1920,
                h: 1080
            };
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const m of shown) {
            const s = Displays.logicalSize(m);
            x0 = Math.min(x0, m.x);
            y0 = Math.min(y0, m.y);
            x1 = Math.max(x1, m.x + s.w);
            y1 = Math.max(y1, m.y + s.h);
        }
        return {
            x: x0 - margin / 2,
            y: y0 - margin / 4,
            w: x1 - x0 + margin,
            h: y1 - y0 + margin / 2
        };
    }
    readonly property real factor: Math.min(width / bounds.w, height / bounds.h)
    readonly property real originX: (width - bounds.w * factor) / 2
    readonly property real originY: (height - bounds.h * factor) / 2

    signal selectRequested(name: string)
    signal moveRequested(name: string, x: int, y: int)

    implicitHeight: 230

    function toX(lx: real): real {
        return originX + (lx - bounds.x) * factor;
    }

    function toY(ly: real): real {
        return originY + (ly - bounds.y) * factor;
    }

    // Position that sits flush against, or aligned with, the nearest neighbouring edges
    function snapped(m: var, x: real, y: real): var {
        const s = Displays.logicalSize(m);
        const threshold = 50;
        let bestX = x, bestY = y, dx = threshold, dy = threshold;
        for (const o of shown) {
            if (o.name === m.name)
                continue;
            const os = Displays.logicalSize(o);
            for (const cx of [o.x + os.w, o.x - s.w, o.x, o.x + os.w - s.w]) {
                if (Math.abs(cx - x) < dx) {
                    dx = Math.abs(cx - x);
                    bestX = cx;
                }
            }
            for (const cy of [o.y + os.h, o.y - s.h, o.y, o.y + os.h - s.h]) {
                if (Math.abs(cy - y) < dy) {
                    dy = Math.abs(cy - y);
                    bestY = cy;
                }
            }
        }
        return {
            x: Math.round(bestX),
            y: Math.round(bestY)
        };
    }

    function overlaps(m: var, x: real, y: real): bool {
        const s = Displays.logicalSize(m);
        return shown.some(o => {
            if (o.name === m.name)
                return false;
            const os = Displays.logicalSize(o);
            return x < o.x + os.w && x + s.w > o.x && y < o.y + os.h && y + s.h > o.y;
        });
    }

    Repeater {
        model: root.shown

        StyledRect {
            id: tile

            required property var modelData
            readonly property var size: Displays.logicalSize(modelData)
            readonly property bool isSelected: modelData.name === root.selected
            readonly property var mirrors: root.mirrored.filter(m => m.mirrorOf === modelData.name)

            x: root.toX(modelData.x)
            y: root.toY(modelData.y)
            width: size.w * root.factor
            height: size.h * root.factor
            radius: Tokens.rounding.small
            color: isSelected ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 3)
            border.width: isSelected ? 2 : 1
            border.color: isSelected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            z: drag.active ? 10 : 0

            Behavior on x {
                enabled: !drag.active
                Anim {}
            }
            Behavior on y {
                enabled: !drag.active
                Anim {}
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.small * 2
                spacing: 0

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: tile.modelData.name
                    color: tile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: `${tile.modelData.width}×${tile.modelData.height}`
                    color: tile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: tile.mirrors.length > 0
                    text: Tr.tr("Mirrored: %1").arg(tile.mirrors.map(m => m.name).join(", "))
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            TapHandler {
                onTapped: root.selectRequested(tile.modelData.name)
            }

            DragHandler {
                id: drag

                target: tile
                onActiveChanged: {
                    root.selectRequested(tile.modelData.name);
                    if (active)
                        return;
                    const lx = (tile.x - root.originX) / root.factor + root.bounds.x;
                    const ly = (tile.y - root.originY) / root.factor + root.bounds.y;
                    const pos = root.snapped(tile.modelData, lx, ly);
                    if (root.overlaps(tile.modelData, pos.x, pos.y) || (pos.x === tile.modelData.x && pos.y === tile.modelData.y)) {
                        // Refuse: glide back to where it was
                        tile.x = Qt.binding(() => root.toX(tile.modelData.x));
                        tile.y = Qt.binding(() => root.toY(tile.modelData.y));
                        return;
                    }
                    tile.x = Qt.binding(() => root.toX(tile.modelData.x));
                    tile.y = Qt.binding(() => root.toY(tile.modelData.y));
                    root.moveRequested(tile.modelData.name, pos.x, pos.y);
                }
            }
        }
    }
}
