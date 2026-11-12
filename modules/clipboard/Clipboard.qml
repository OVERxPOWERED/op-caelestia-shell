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

    function toggleTab(tab: string): void {
        const s = ShellState.forActive() || (Screens.screens.length > 0 ? ShellState.forScreen(Screens.screens[0]) : null);
        if (s) {
            if (s.clipboard && root.requestedTab === tab) {
                s.clipboard = false;
            } else {
                root.requestedTab = tab;
                s.clipboard = true;
            }
        }
    }

    function openTab(tab: string): void {
        const s = ShellState.forActive() || (Screens.screens.length > 0 ? ShellState.forScreen(Screens.screens[0]) : null);
        if (s) {
            root.requestedTab = tab;
            s.clipboard = true;
        }
    }

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

                    // Backdrop dim & click-catcher
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            content.requestClose();
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0.25)
                            opacity: content.cardOpacity
                        }
                    }

                    ClipboardContent {
                        id: content
                        anchors.fill: parent
                        screen: win.screen
                        initialTab: root.requestedTab

                        onCloseRequested: {
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
            root.openTab("clipboard");
        }

        function openTab(tab: string): void {
            root.openTab(tab || "clipboard");
        }

        function close(): void {
            for (let i = 0; i < Screens.screens.length; i++) {
                const s = ShellState.forScreen(Screens.screens[i]);
                if (s) s.clipboard = false;
            }
        }

        function toggle(): void {
            root.toggleTab("clipboard");
        }

        function toggleTab(tab: string): void {
            root.toggleTab(tab || "clipboard");
        }
    }

    CustomShortcut {
        name: "clipboard"
        description: "Toggle native Caelestia clipboard"
        onPressed: {
            root.toggleTab("clipboard");
        }
    }

    CustomShortcut {
        name: "emojis"
        description: "Toggle native Caelestia emojis and symbols"
        onPressed: {
            root.toggleTab("emojis");
        }
    }
}
