pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components.containers
import qs.services

Scope {
    id: root

    function applyBlurRule(): void {
        const enabled = Colours.transparency.enabled;
        const ignoreAlpha = Math.min(0.57, Math.max(0, Colours.transparency.base - 0.03));
        const ns = "caelestia-voicepill";
        Hypr.extras.batchMessage(Hypr.usingLua ? [
            `eval hl.layer_rule({ match = { namespace = "${ns}" }, blur = ${enabled} })`,
            `eval hl.layer_rule({ match = { namespace = "${ns}" }, ignore_alpha = ${ignoreAlpha} })`
        ] : [
            `keyword layerrule blur ${enabled ? 1 : 0}, match:namespace ${ns}`,
            `keyword layerrule ignore_alpha ${ignoreAlpha}, match:namespace ${ns}`
        ]);
    }

    Component.onCompleted: applyBlurRule()

    Connections {
        function onConfigReloaded(): void {
            root.applyBlurRule();
        }

        function onUsingLuaChanged(): void {
            root.applyBlurRule();
        }

        target: Hypr
    }

    Connections {
        function onEnabledChanged(): void {
            root.applyBlurRule();
        }

        function onBaseChanged(): void {
            root.applyBlurRule();
        }

        target: Colours.transparency
    }

    Variants {
        model: Screens.screens

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

                readonly property real padX: Math.max(12, (content.width * (VoiceTyping.scaleFactor - 1)) / 2 + 12)
                readonly property real padY: Math.max(12, (content.height * (VoiceTyping.scaleFactor - 1)) / 2 + 12)

                x: Math.max(0, content.x - padX)
                y: Math.max(0, content.y + content.animY - padY)
                width: content.width + padX * 2
                height: content.height + padY * 2
            }

            VoicePillContent {
                id: content

                parentWidth: win.width
                parentHeight: win.height
            }
        }
    }
}
}
