pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    id: root

    Variants {
        model: Screens.screens

        Scope {
            id: scope

            required property ShellScreen modelData
            readonly property ScreenState screenState: ShellState.forScreen(modelData)

            LazyLoader {
                id: loader

                active: scope.screenState?.clipboard ?? false

                StyledWindow {
                    id: win

                    screen: scope.modelData
                    name: "clipboard"
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                    anchors.top: true
                    anchors.bottom: true
                    anchors.right: true
                    anchors.left: true

                    // Backdrop click-catcher
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("[Clipboard] Backdrop clicked -> closing");
                            if (scope.screenState) scope.screenState.clipboard = false;
                        }
                    }

                    ClipboardContent {
                        anchors.fill: parent
                        screen: win.screen

                        onCloseRequested: {
                            console.log("[Clipboard] onCloseRequested -> closing");
                            if (scope.screenState) scope.screenState.clipboard = false;
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "clipboard"

        function open(): void {
            const s = ShellState.forActive() || (Screens.screens.length > 0 ? ShellState.forScreen(Screens.screens[0]) : null);
            console.log("[Clipboard IPC] open called, screenState:", s, "modelData:", s ? s.modelData?.name : "none", "screens count:", Screens.screens.length);
            if (s) {
                s.clipboard = true;
            }
        }

        function close(): void {
            for (let i = 0; i < Screens.screens.length; i++) {
                const s = ShellState.forScreen(Screens.screens[i]);
                if (s) s.clipboard = false;
            }
        }

        function toggle(): void {
            const s = ShellState.forActive() || (Screens.screens.length > 0 ? ShellState.forScreen(Screens.screens[0]) : null);
            console.log("[Clipboard IPC] toggle called, screenState:", s);
            if (s) {
                s.clipboard = !s.clipboard;
            }
        }
    }

    CustomShortcut {
        name: "clipboardPreview"
        description: "Toggle native Caelestia clipboard preview"
        onPressed: {
            const s = ShellState.forActive();
            if (s) {
                s.clipboard = !s.clipboard;
            }
        }
    }

    CustomShortcut {
        name: "clipboard"
        description: "Toggle native Caelestia clipboard"
        onPressed: {
            const s = ShellState.forActive();
            if (s) {
                s.clipboard = !s.clipboard;
            }
        }
    }
}
