pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinTabs: ({
        dashboard: Tr.tr("Dashboard"),
        media: Tr.tr("Media"),
        focus: Tr.tr("Focus"),
        performance: Tr.tr("Performance"),
        weather: Tr.tr("Weather")
    })

    title: Tr.tr("Dashboard")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Enabled", "toggle label")
            checked: Config.dashboard.enabled
            onToggled: GlobalConfig.dashboard.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            checked: Config.dashboard.showOnHover
            onToggled: GlobalConfig.dashboard.showOnHover = checked
        }

        ToggleRow {
            text: Tr.tr("Show clock seconds")
            subtext: Tr.tr("Display seconds for the clock in the main panel")
            checked: Config.dashboard.showClockSeconds
            onToggled: GlobalConfig.dashboard.showClockSeconds = checked
        }

        NavRow {
            last: true
            icon: "timer"
            text: Tr.tr("Focus tab")
            onClicked: root.nState.openSubPage(15)
        }

        // Tabs
        SectionHeader {
            text: Tr.tr("Tabs")
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinTabs[item.id];
                if (prettyName)
                    return prettyName;
                const label = item.id.replace(/([A-Z])/g, " $1");
                return label.charAt(0).toUpperCase() + label.slice(1).toLowerCase();
            }

            function toggledFor(item: var): bool {
                return item.enabled;
            }

            z: 1
            first: true
            values: Config.dashboard.tabs.values
            onItemMoved: (from, to) => GlobalConfig.dashboard.tabs.move(from, to)
            onItemRemoved: index => GlobalConfig.dashboard.tabs.remove(index)
            onItemToggled: (index, checked) => {
                GlobalConfig.dashboard.tabs.at(index).enabled = checked;
            }
        }

        DialogSelectButton {
            id: addTabContainer

            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Add tab")
            header: Tr.tr("Add new tab")
            acceptLabel: Tr.trCtx("Add", "button")

            model: {
                const builtins = Object.keys(root.builtinTabs).map(k => ({
                    id: k,
                    label: root.builtinTabs[k]
                }));
                return builtins.filter(b => !Config.dashboard.tabs.values.some(v => v.id === b.id));
            }

            onAccepted: {
                if (!selectedItem)
                    return;

                GlobalConfig.dashboard.tabs.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }

        // Performance widgets
        SectionHeader {
            text: Tr.tr("Performance widgets")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Battery")
            checked: Config.dashboard.performance.showBattery
            onToggled: GlobalConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            text: Tr.tr("GPU")
            checked: Config.dashboard.performance.showGpu
            onToggled: GlobalConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            text: Tr.tr("CPU")
            checked: Config.dashboard.performance.showCpu
            onToggled: GlobalConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            text: Tr.tr("Memory")
            checked: Config.dashboard.performance.showMemory
            onToggled: GlobalConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            text: Tr.tr("Storage")
            checked: Config.dashboard.performance.showStorage
            onToggled: GlobalConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Network")
            checked: Config.dashboard.performance.showNetwork
            onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        StepperRow {
            first: true
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the dashboard opens")
            value: Config.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dashboard.dragThreshold = v
        }
    }
}
