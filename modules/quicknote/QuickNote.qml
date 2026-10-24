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

                active: scope.screenState?.quicknote ?? false

                StyledWindow {
                    id: win

                    screen: scope.modelData
                    name: "quicknote"
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                    anchors.top: true
                    anchors.bottom: true
                    anchors.right: true
                    anchors.left: true

                    QuickNoteContent {
                        id: content
                        anchors.fill: parent
                        screen: win.screen

                        onCloseRequested: {
                            scope.screenState.quicknote = false;
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "quicknote"

        function open(): void {
            const s = ShellState.forActive();
            if (s) {
                QuickNoteState.captureContext();
                s.quicknote = true;
            }
        }

        function close(): void {
            const s = ShellState.forActive();
            if (s) s.quicknote = false;
        }

        function toggle(): void {
            const s = ShellState.forActive();
            if (s) {
                if (!s.quicknote)
                    QuickNoteState.captureContext();
                s.quicknote = !s.quicknote;
            }
        }
    }
}
