pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services
import "./components"

Item {
    id: root

    required property ShellScreen screen
    signal closeRequested

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)

    focus: true

    Keys.onEscapePressed: event => {
        event.accepted = true;
        root.closeRequested();
    }

    Keys.onLeftPressed: event => {
        event.accepted = true;
        if (OverviewState.activeTab === 0) {
            const workspaces = OverviewState.getNormalWorkspaces(root.monitor);
            if (workspaces.length > 0) {
                const curIdx = workspaces.findIndex(w => w.id === Hypr.focusedWorkspace?.id);
                if (curIdx > 0) {
                    OverviewState.focusWorkspace(workspaces[curIdx - 1].id);
                }
            }
        }
    }

    Keys.onRightPressed: event => {
        event.accepted = true;
        if (OverviewState.activeTab === 0) {
            const workspaces = OverviewState.getNormalWorkspaces(root.monitor);
            if (workspaces.length > 0) {
                const curIdx = workspaces.findIndex(w => w.id === Hypr.focusedWorkspace?.id);
                if (curIdx >= 0 && curIdx < workspaces.length - 1) {
                    OverviewState.focusWorkspace(workspaces[curIdx + 1].id);
                }
            }
        }
    }

    // Blurred Glassmorphic Backdrop
    StyledRect {
        id: bg
        anchors.fill: parent
        color: Colours.tPalette.m3surface
        opacity: Colours.transparency.enabled ? 0.55 : 0.75

        TapHandler {
            onTapped: root.focus = true
        }
    }

    Item {
        anchors.fill: parent

        // 1. Top Header (Search & Tabs)
        Header {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            onCloseRequested: root.closeRequested()
        }

        // 2. Bottom Footer (Keys & Gestures)
        NavigationFooter {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tokens.padding.medium
        }

        // 3. Middle Content Area (Switched by active tab)
        Item {
            anchors.top: header.bottom
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Tokens.padding.small
            anchors.bottomMargin: Tokens.padding.small
            clip: false

            // Tab 0: Workspaces Carousel
            WorkspaceCarousel {
                anchors.centerIn: parent
                width: parent.width
                monitor: root.monitor
                visible: OverviewState.activeTab === 0
                opacity: visible ? 1.0 : 0.0
                onCloseRequested: root.closeRequested()

                Behavior on opacity { Anim {} }
            }

            // Tab 1: Special Scratchpads Carousel
            SpecialCarousel {
                anchors.centerIn: parent
                width: parent.width
                monitor: root.monitor
                visible: OverviewState.activeTab === 1
                opacity: visible ? 1.0 : 0.0
                onCloseRequested: root.closeRequested()

                Behavior on opacity { Anim {} }
            }

            // Tab 2: All Windows Grid
            AllWindowsGrid {
                anchors.centerIn: parent
                width: parent.width
                monitor: root.monitor
                visible: OverviewState.activeTab === 2
                opacity: visible ? 1.0 : 0.0
                onCloseRequested: root.closeRequested()

                Behavior on opacity { Anim {} }
            }
        }
    }
}
