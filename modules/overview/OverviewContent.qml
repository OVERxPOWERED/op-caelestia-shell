pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
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

            // Tab 0: Workspaces Carousel (Linear Mode)
            WorkspaceCarousel {
                anchors.centerIn: parent
                width: parent.width
                monitor: root.monitor
                visible: OverviewState.activeTab === 0 && !OverviewState.gridMode
                opacity: visible ? 1.0 : 0.0
                onCloseRequested: root.closeRequested()

                Behavior on opacity { Anim {} }
            }

            // Tab 0: Workspaces Grid (Grid Mode)
            WorkspaceGrid {
                anchors.centerIn: parent
                width: parent.width
                monitor: root.monitor
                visible: OverviewState.activeTab === 0 && OverviewState.gridMode
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

        // Global Drag Overlay following cursor
        StyledRect {
            id: dragOverlay
            visible: OverviewState.isDragging
            x: OverviewState.dragGlobalX - width / 2
            y: OverviewState.dragGlobalY - height / 2
            implicitWidth: OverviewState.draggingWorkspace ? 300 : 260
            implicitHeight: 56
            radius: Tokens.rounding.medium
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
            border.width: 2
            border.color: Colours.palette.m3primary
            opacity: 0.95
            z: 9999

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                IconImage {
                    source: OverviewState.dragIcon
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: source !== ""
                }

                MaterialIcon {
                    text: OverviewState.draggingWorkspace ? "desktop_windows" : "web_asset"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3primary
                    visible: OverviewState.dragIcon === ""
                }

                StyledText {
                    Layout.fillWidth: true
                    text: OverviewState.dragTitle
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurface
                }

                // Smart Action Target Badge
                StyledRect {
                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: 26
                    radius: Tokens.rounding.full
                    color: {
                        if (OverviewState.draggingWindow) {
                            return OverviewState.dropTargetWsId >= 0
                                ? Colours.palette.m3primaryContainer
                                : Colours.palette.m3secondaryContainer;
                        } else {
                            const origin = OverviewState.dragOriginIndex;
                            const target = OverviewState.dragTargetIndex;
                            return (origin >= 0 && target >= 0 && origin !== target)
                                ? Colours.palette.m3tertiaryContainer
                                : Colours.palette.m3surfaceContainerHigh;
                        }
                    }

                    StyledText {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: {
                            if (OverviewState.draggingWindow) {
                                return OverviewState.dropTargetWsId >= 0
                                    ? `→ Ws ${OverviewState.dropTargetWsId}`
                                    : `+ Ws ${OverviewState.nextAvailableWsId}`;
                            } else if (OverviewState.draggingWorkspace) {
                                const origin = OverviewState.dragOriginIndex;
                                const target = OverviewState.dragTargetIndex;
                                return (origin >= 0 && target >= 0 && origin !== target)
                                    ? `→ Slot ${target + 1}`
                                    : qsTr("Reorder");
                            }
                            return "";
                        }
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: {
                            if (OverviewState.draggingWindow) {
                                return OverviewState.dropTargetWsId >= 0
                                    ? Colours.palette.m3onPrimaryContainer
                                    : Colours.palette.m3onSecondaryContainer;
                            } else {
                                const origin = OverviewState.dragOriginIndex;
                                const target = OverviewState.dragTargetIndex;
                                return (origin >= 0 && target >= 0 && origin !== target)
                                    ? Colours.palette.m3onTertiaryContainer
                                    : Colours.palette.m3onSurface;
                            }
                        }
                    }
                }
            }
        }
    }
}
