pragma ComponentBehavior: Bound

import "bluetooth"
import "network"
import "audio"
import "appearance"
import "taskbar"
import "launcher"
import qs.components
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {
    id: root

    required property Session session

    color: "transparent"
    clip: true
    focus: false
    activeFocusOnTab: false

    // Clear focus when clicking anywhere in the panes area
    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: function(mouse) {
            root.focus = true;
            mouse.accepted = false;
        }
    }

    // Clear focus when switching panes
    Connections {
        target: root.session

        function onActiveIndexChanged(): void {
            root.focus = true;
        }
    }

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height
        clip: true

        property bool animationComplete: true
        // Track if initial opening animation has completed
        // During initial opening, only the active pane loads to avoid hiccups
        property bool initialOpeningComplete: false

        Timer {
            id: animationDelayTimer
            interval: Appearance.anim.durations.normal
            onTriggered: {
                layout.animationComplete = true;
            }
        }

        // Timer to detect when initial opening animation completes
        // Uses large duration to cover both normal and detached opening cases
        Timer {
            id: initialOpeningTimer
            interval: Appearance.anim.durations.large
            running: true
            onTriggered: {
                layout.initialOpeningComplete = true;
            }
        }

        Pane {
            index: 0
            sourceComponent: NetworkingPane {
                session: root.session
            }
        }

        Pane {
            index: 1
            sourceComponent: BtPane {
                session: root.session
            }
        }

        Pane {
            index: 2
            sourceComponent: AudioPane {
                session: root.session
            }
        }

        Pane {
            index: 3
            sourceComponent: AppearancePane {
                session: root.session
            }
        }

        Pane {
            index: 4
            sourceComponent: TaskbarPane {
                session: root.session
            }
        }

        Pane {
            index: 5
            sourceComponent: LauncherPane {
                session: root.session
            }
        }

        Behavior on y {
            Anim {}
        }

        Connections {
            target: root.session
            function onActiveIndexChanged(): void {
                // Mark animation as incomplete and start delay timer
                layout.animationComplete = false;
                animationDelayTimer.restart();
            }
        }
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent

        implicitWidth: root.width
        implicitHeight: root.height

        // Track if this pane has ever been loaded to enable caching
        property bool hasBeenLoaded: false

        Loader {
            id: loader

            anchors.fill: parent
            clip: false
            asynchronous: true
            active: {
                const diff = Math.abs(root.session.activeIndex - pane.index);
                const isActivePane = diff === 0;
                
                // During initial opening animation, only load the active pane
                // This prevents hiccups from multiple panes loading simultaneously
                if (!layout.initialOpeningComplete) {
                    if (isActivePane) {
                        pane.hasBeenLoaded = true;
                        return true;
                    }
                    // Defer all other panes until initial opening completes
                    return false;
                }
                
                // After initial opening, allow current and adjacent panes for smooth transitions
                if (diff <= 1) {
                    pane.hasBeenLoaded = true;
                    return true;
                }
                
                // For distant panes that have been loaded before, keep them active to preserve cached data
                // Only wait for animation if pane hasn't been loaded yet
                if (pane.hasBeenLoaded) {
                    return true;
                }
                
                // For new distant panes, wait until animation completes to avoid heavy loading during transition
                return layout.animationComplete;
            }
            
            onItemChanged: {
                // Mark pane as loaded when item is created
                if (item) {
                    pane.hasBeenLoaded = true;
                }
            }
        }
    }
}
