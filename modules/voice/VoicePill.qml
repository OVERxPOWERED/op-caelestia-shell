pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components.containers
import qs.services

Variants {
    id: root

    function applyBlurRule(): void {
        const ns = "caelestia-voicepill";
        Hypr.extras.batchMessage(Hypr.usingLua ? [
            `eval hl.layer_rule({ match = { namespace = "${ns}" }, blur = true })`,
            `eval hl.layer_rule({ match = { namespace = "${ns}" }, ignore_alpha = 0.15 })`
        ] : [
            `keyword layerrule blur 1, match:namespace ${ns}`,
            `keyword layerrule ignore_alpha 0.15, match:namespace ${ns}`
        ]);
    }

    model: Screens.screens

    Component.onCompleted: applyBlurRule()

    Connections {
        function onConfigReloaded(): void {
            root.applyBlurRule();
        }

        target: Hypr
    }

    Scope {
        id: scope

        required property ShellScreen modelData

        StyledWindow {
            id: win

            screen: scope.modelData
            name: "voicepill"

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            color: "transparent"

            mask: {
                if (!VoiceTyping.active)
                    return emptyMask;
                if (content.isDragging || content.isPressed)
                    return fullscreenMask;
                return activeMask;
            }

            Region {
                id: emptyMask
            }

            Region {
                id: fullscreenMask

                x: 0
                y: 0
                width: win.width
                height: win.height
            }

            Region {
                id: activeMask

                x: Math.max(0, content.x - 8)
                y: Math.max(0, content.y + content.animY - 8)
                width: content.width + 16
                height: content.height + 16
            }

            VoicePillContent {
                id: content

                parentWidth: win.width
                parentHeight: win.height
            }
        }
    }
}
