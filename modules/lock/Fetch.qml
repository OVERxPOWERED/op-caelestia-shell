pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils

StyledClippingRect {
    id: root

    required property real rootHeight
    readonly property string gifSource: Paths.absolutePath(Config.paths.lockGif)
    property int lastFrame: -1
    property bool manualPlayback: false
    property int stillTicks: 0

    implicitHeight: Math.max(190, Math.min(root.rootHeight * 0.42, width * 0.72))
    radius: Tokens.rounding.extraLarge

    AnimatedImage {
        id: gifPlayer

        anchors.fill: parent

        source: root.gifSource
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
        playing: root.visible && width > 0 && height > 0
        paused: false
        speed: 1
        asynchronous: true
        cache: false
        fillMode: AnimatedImage.PreserveAspectCrop

        onSourceChanged: {
            root.lastFrame = -1;
            root.manualPlayback = false;
            root.stillTicks = 0;
            paused = false;
        }

        onStatusChanged: {
            if (status === AnimatedImage.Ready) {
                root.manualPlayback = false;
                paused = false;
                currentFrame = 0;
            }
        }
    }

    Timer {
        interval: root.manualPlayback ? 120 : 700
        repeat: true
        running: root.visible && gifPlayer.status === AnimatedImage.Ready && gifPlayer.frameCount > 1

        onTriggered: {
            if (gifPlayer.paused)
                gifPlayer.paused = false;

            if (root.manualPlayback) {
                gifPlayer.currentFrame = (gifPlayer.currentFrame + 1) % gifPlayer.frameCount;
                root.lastFrame = gifPlayer.currentFrame;
                return;
            }

            if (gifPlayer.currentFrame !== root.lastFrame) {
                root.lastFrame = gifPlayer.currentFrame;
                root.stillTicks = 0;
                return;
            }

            if (++root.stillTicks < 2)
                return;

            root.stillTicks = 0;
            root.manualPlayback = true;
            gifPlayer.currentFrame = (gifPlayer.currentFrame + 1) % gifPlayer.frameCount;
            root.lastFrame = gifPlayer.currentFrame;
        }
    }
}
