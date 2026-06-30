pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpaper {}
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled

            readonly property real leftPct: Config.background.desktopClock.position.left
            readonly property real topPct: Config.background.desktopClock.position.top
            readonly property real rightPct: Config.background.desktopClock.position.right
            readonly property real bottomPct: Config.background.desktopClock.position.bottom
            readonly property real barOffset: Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            x: {
                if (leftPct >= 0)
                    return Math.max(barOffset, (parent.width * leftPct / 100) - (width / 2));
                else if (rightPct >= 0)
                    return parent.width - (parent.width * rightPct / 100) - width;
                else
                    return parent.width - width - Tokens.padding.extraLargeIncreased;
            }

            y: {
                if (topPct >= 0)
                    return Math.max(0, (parent.height * topPct / 100) - (height / 2));
                else if (bottomPct >= 0)
                    return parent.height - (parent.height * bottomPct / 100) - height;
                else
                    return parent.height - height - Tokens.padding.extraLargeIncreased;
            }

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
