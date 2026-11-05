pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> strategyItems: [
        MenuItem {
            text: Tr.tr("Dedicated blocks per monitor (Independent)")
            icon: "splitscreen"
        },
        MenuItem {
            text: Tr.tr("Shared / Dynamic pool (Unified)")
            icon: "layers"
        },
        MenuItem {
            text: Tr.tr("Interleaved (Odd / Even)")
            icon: "compare_arrows"
        },
        MenuItem {
            text: Tr.tr("Primary display only")
            icon: "desktop_windows"
        }
    ]

    readonly property list<MenuItem> perDisplayItems: [
        MenuItem {
            text: Tr.tr("10 Workspaces per screen")
            icon: "looks_one"
        },
        MenuItem {
            text: Tr.tr("5 Workspaces per screen")
            icon: "looks_5"
        }
    ]

    readonly property list<MenuItem> scopeItems: [
        MenuItem {
            text: Tr.tr("Sequential on current monitor (r±1)")
            icon: "crop_square"
        },
        MenuItem {
            text: Tr.tr("Open workspaces on current monitor (m±1)")
            icon: "filter_none"
        },
        MenuItem {
            text: Tr.tr("Skip empty workspaces globally (e±1)")
            icon: "fast_forward"
        }
    ]

    readonly property list<MenuItem> fingerItems: [
        MenuItem {
            text: Tr.tr("4 Fingers (Recommended)")
            icon: "back_hand"
        },
        MenuItem {
            text: Tr.tr("3 Fingers")
            icon: "pan_tool"
        }
    ]

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Distribution & Multi-Monitor Strategy
        SectionHeader {
            first: true
            text: Tr.tr("Distribution Strategy")
        }

        SelectRow {
            first: true
            label: Tr.tr("Workspace distribution")
            subtext: Tr.tr("How workspaces are allocated across attached monitors")
            menuItems: root.strategyItems
            active: root.strategyItems[Math.max(0, Math.min(root.strategyItems.length - 1, WorkspaceManager.strategy))]
            onSelected: item => WorkspaceManager.setStrategy(root.strategyItems.indexOf(item))
        }

        SelectRow {
            label: Tr.tr("Workspaces per display")
            subtext: Tr.tr("Number of workspaces allocated to each monitor block")
            menuItems: root.perDisplayItems
            active: WorkspaceManager.workspacesPerDisplay === 5 ? root.perDisplayItems[1] : root.perDisplayItems[0]
            onSelected: item => WorkspaceManager.setWorkspacesPerDisplay(root.perDisplayItems.indexOf(item) === 1 ? 5 : 10)
        }

        SelectRow {
            last: true
            label: Tr.tr("Navigation scope")
            subtext: Tr.tr("Target range for keyboard shortcuts and gestures")
            menuItems: root.scopeItems
            active: root.scopeItems[Math.max(0, Math.min(root.scopeItems.length - 1, WorkspaceManager.navigationScope))]
            onSelected: item => WorkspaceManager.setNavigationScope(root.scopeItems.indexOf(item))
        }

        // Touchpad Gestures
        SectionHeader {
            text: Tr.tr("Touchpad Gestures")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Fluid 1:1 workspace swipe")
            subtext: Tr.tr("Direct manipulation swipe with real-time finger tracking")
            checked: WorkspaceManager.gestureSwipe
            onToggled: WorkspaceManager.setGestureSwipe(checked)
        }

        SelectRow {
            last: true
            label: Tr.tr("Swipe finger count")
            subtext: Tr.tr("Number of fingers used for horizontal workspace swiping")
            menuItems: root.fingerItems
            active: WorkspaceManager.gestureFingers === 3 ? root.fingerItems[1] : root.fingerItems[0]
            onSelected: item => WorkspaceManager.setGestureFingers(root.fingerItems.indexOf(item) === 1 ? 3 : 4)
        }

        // Taskbar Display Options
        SectionHeader {
            text: Tr.tr("Taskbar Presentation")
        }

        StepperRow {
            first: true
            label: Tr.trCtx("Shown", "bar workspaces")
            subtext: Tr.tr("Number of workspaces displayed on the bar")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            text: Tr.trCtx("Active indicator", "bar workspaces")
            checked: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.trCtx("Active trail", "bar workspaces")
            checked: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.trCtx("Occupied background", "bar workspaces")
            checked: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show unoccupied", "bar workspaces")
            subtext: Tr.tr("Show workspaces that are inactive and empty")
            checked: Config.bar.workspaces.showUnoccupied
            onToggled: GlobalConfig.bar.workspaces.showUnoccupied = checked
        }

        ToggleRow {
            text: Tr.trCtx("Per monitor", "bar workspaces")
            subtext: Tr.tr("Hide workspaces not on the current monitor")
            checked: Config.bar.workspaces.perMonitor
            onToggled: GlobalConfig.bar.workspaces.perMonitor = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show windows", "bar workspaces")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            checked: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: Tr.trCtx("Windows on special workspaces", "bar workspaces")
            checked: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            last: true
            label: Tr.trCtx("Max window icons", "bar workspaces")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }
    }
}
