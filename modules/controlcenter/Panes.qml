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

    // Expose initialOpeningComplete so parent can check if opening animation is done
    readonly property bool initialOpeningComplete: layout.initialOpeningComplete

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
        
        // Function to compute if this pane should be active
        function updateActive(): void {
            const diff = Math.abs(root.session.activeIndex - pane.index);
            const isActivePane = diff === 0;
            let shouldBeActive = false;
            
            // During initial opening animation, only load the active pane
            // This prevents hiccups from multiple panes loading simultaneously
            if (!layout.initialOpeningComplete) {
                shouldBeActive = isActivePane;
            } else {
                // After initial opening, allow current and adjacent panes for smooth transitions
                if (diff <= 1) {
                    shouldBeActive = true;
                } else if (pane.hasBeenLoaded) {
                    // For distant panes that have been loaded before, keep them active to preserve cached data
                    shouldBeActive = true;
                } else {
                    // For new distant panes, wait until animation completes to avoid heavy loading during transition
                    shouldBeActive = layout.animationComplete;
                }
            }
            
            loader.active = shouldBeActive;
        }

        Loader {
            id: loader

            anchors.fill: parent
            clip: false
            asynchronous: true
            active: false
            
            Component.onCompleted: {
                pane.updateActive();
            }
            
            onActiveChanged: {
                // Mark pane as loaded when it becomes active
                if (active && !pane.hasBeenLoaded) {
                    pane.hasBeenLoaded = true;
                }
            }
            
            onItemChanged: {
                // Mark pane as loaded when item is created
                if (item) {
                    pane.hasBeenLoaded = true;
                }
            }
        }
        
        Connections {
            target: root.session
            function onActiveIndexChanged(): void {
                pane.updateActive();
            }
        }
        
        Connections {
            target: layout
            function onInitialOpeningCompleteChanged(): void {
                pane.updateActive();
            }
            function onAnimationCompleteChanged(): void {
                pane.updateActive();
            }
        }
    }
}
