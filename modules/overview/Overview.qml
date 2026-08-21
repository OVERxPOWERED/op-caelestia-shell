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
import "components"

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

                active: scope.screenState?.overview ?? false

                StyledWindow {
                    id: win

                    screen: scope.modelData
                    name: "overview"
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                    anchors.top: true
                    anchors.bottom: true
                    anchors.right: true
                    anchors.left: true

                    OverviewContent {
                        id: content
                        anchors.fill: parent
                        screen: win.screen

                        onCloseRequested: {
                            scope.screenState.overview = false;
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "overview"

        function open(): void {
            const s = ShellState.forActive();
            if (s) {
                OverviewState.reset();
                s.overview = true;
            }
        }

        function close(): void {
            const s = ShellState.forActive();
            if (s) s.overview = false;
        }

        function toggle(): void {
            const s = ShellState.forActive();
            if (s) {
                if (!s.overview) OverviewState.reset();
                s.overview = !s.overview;
            }
        }

        function tab(tabIndex: int): void {
            OverviewState.activeTab = tabIndex;
        }
    }
}
