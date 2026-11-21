pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    property bool onClient
    property bool animReady
    property bool dragging
    property real lastPointerX: -1
    property real lastPointerY: -1

    property real realBorderWidth: onClient ? (Hypr.options["general:border_size"] ?? 1) : 2
    property real realRounding: onClient ? (Hypr.options["decoration:rounding"] ?? 0) : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    property list<var> clients: {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const special = mon.lastIpcObject?.specialWorkspace;
        const targetWs = (special?.name && special.name !== "") ? special.name : (mon.activeWorkspace?.name ?? mon.activeWorkspace?.id);
        if (targetWs === undefined || targetWs === "")
            return [];

        const wsClients = Hypr.toplevelsForWs(targetWs);
        const monId = mon.id;
        const pinnedClients = Hypr.toplevels.values.filter(t => {
            const ipc = t?.lastIpcObject;
            return ipc?.pinned && ipc?.monitor === monId && !wsClients.includes(t) && !Hypr.isToplevelIgnored(t);
        });

        return wsClients.concat(pinnedClients).filter(t => !t?.lastIpcObject?.hidden).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then topmost focus
            const ac = a?.lastIpcObject;
            const bc = b?.lastIpcObject;
            if (!ac || !bc)
                return !ac - !bc; // Missing IPC last
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating) || ((ac.focusHistoryID ?? 0) - (bc.focusHistoryID ?? 0));
        });
    }

    function checkClientRects(x: real, y: real): bool {
        if (x < 0 || y < 0 || x > screen.width || y > screen.height)
            return false;

        for (const client of clients) {
            if (!client)
                continue;

            const ipc = client.lastIpcObject;
            if (!ipc?.at || !ipc?.size)
                continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = ipc;
            cx -= screen.x;
            cy -= screen.y;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                onClient = true;
                sx = cx;
                sy = cy;
                ex = cx + cw;
                ey = cy + ch;
                return true;
            }
        }
        return false;
    }

    function save(): void {
        const tx = Math.max(0, Math.min(sx, ex));
        const ty = Math.max(0, Math.min(sy, ey));
        const tex = Math.min(screen.width, Math.max(sx, ex));
        const tey = Math.min(screen.height, Math.max(sy, ey));
        const cropW = Math.max(1, Math.floor(tex - tx));
        const cropH = Math.max(1, Math.floor(tey - ty));
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        CUtils.saveItem(screencopy, tmpfile, Qt.rect(Math.ceil(tx), Math.ceil(ty), cropW, cropH), path => {
            if (root.loader.clipboardOnly) {
                Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < " + path]);
                Quickshell.execDetached(["notify-send", "-a", "caelestia-cli", "-i", path, Tr.tr("Screenshot taken"), Tr.tr("Screenshot copied to clipboard")]);
            } else {
                Quickshell.execDetached(["swappy", "-f", path]);
            }
            if (!root.loader.freeze) {
                screencopy.visible = false;
                overlay.visible = border.visible = true;
            }
            closeAnim.start();
        });
    }

    onClientsChanged: {
        if (lastPointerX >= 0 && lastPointerY >= 0 && !pressed)
            checkClientRects(lastPointerX, lastPointerY);
    }

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: Qt.CrossCursor

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        // Break binding if frozen
        if (loader.freeze)
            clients = clients;

        opacity = 1;

        const ipc = clients[0]?.lastIpcObject;
        if (ipc?.at && ipc?.size) {
            const cx = ipc.at[0] - screen.x;
            const cy = ipc.at[1] - screen.y;
            onClient = true;
            sx = cx;
            sy = cy;
            ex = cx + ipc.size[0];
            ey = cy + ipc.size[1];
        } else {
            sx = screen.width / 2 - 100;
            sy = screen.height / 2 - 100;
            ex = screen.width / 2 + 100;
            ey = screen.height / 2 + 100;
        }
    }

    onPressed: event => {
        ssx = event.x;
        ssy = event.y;
        dragging = false;
    }

    onReleased: {
        if (closeAnim.running || captureDelay.running)
            return;

        if (root.loader.freeze) {
            save();
        } else {
            overlay.visible = border.visible = false;
            captureDelay.start();
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (pressed) {
            if (dragging || Math.hypot(x - ssx, y - ssy) > 4) {
                dragging = true;
                onClient = false;
                sx = ssx;
                sy = ssy;
                ex = x;
                ey = y;
            }
        } else {
            lastPointerX = x;
            lastPointerY = y;
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Timer {
        id: captureDelay

        interval: 32
        onTriggered: {
            screencopy.visible = true;
            screencopy.active = true;
        }
    }

    Process {
        running: true
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const pos = JSON.parse(text);
                    const px = pos.x - root.screen.x;
                    const py = pos.y - root.screen.y;
                    if (px >= 0 && py >= 0 && px <= root.screen.width && py <= root.screen.height) {
                        root.lastPointerX = px;
                        root.lastPointerY = py;
                        root.checkClientRects(px, py);
                    }
                } catch (e) {
                    // ignore malformed cursorpos
                }
                Qt.callLater(() => root.animReady = true);
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0)
                Qt.callLater(() => root.animReady = true);
        }
    }

    Loader {
        id: screencopy

        z: -1
        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) {
                    root.save();
                }
            }
        }
    }

    StyledRect {
        id: overlay

        anchors.fill: parent
        color: Colours.palette.m3secondaryContainer
        opacity: 0.3

        layer.enabled: true
        layer.effect: Mask {
            maskSource: selectionWrapper
            maskInverted: true
        }
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            radius: root.realRounding
            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    Rectangle {
        id: border

        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: selectionRect.x - root.realBorderWidth
        y: selectionRect.y - root.realBorderWidth
        implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

        Behavior on border.color {
            CAnim {}
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: root.animReady && !root.pressed && !root.loader.closing

        Anim {}
    }

    Behavior on rsy {
        enabled: root.animReady && !root.pressed && !root.loader.closing

        Anim {}
    }

    Behavior on sw {
        enabled: root.animReady && !root.pressed && !root.loader.closing

        Anim {}
    }

    Behavior on sh {
        enabled: root.animReady && !root.pressed && !root.loader.closing

        Anim {}
    }
}
