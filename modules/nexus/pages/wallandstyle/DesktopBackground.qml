pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var clockPresets: [
        { id: "bottom-right", name: qsTr("Bottom right"), left: -1, top: -1, right: 2, bottom: 2 },
        { id: "bottom-left", name: qsTr("Bottom left"), left: 10, top: -1, right: -1, bottom: 2 },
        { id: "bottom-center", name: qsTr("Bottom center"), left: 50, top: -1, right: -1, bottom: 2 },
        { id: "top-left", name: qsTr("Top left"), left: 10, top: 8, right: -1, bottom: -1 },
        { id: "top-center", name: qsTr("Top center"), left: 50, top: 8, right: -1, bottom: -1 },
        { id: "top-right", name: qsTr("Top right"), left: -1, top: 8, right: 2, bottom: -1 },
        { id: "center", name: qsTr("Center"), left: 50, top: 50, right: -1, bottom: -1 }
    ]

    function currentClockPreset(): string {
        const p = Config.background.desktopClock.position;
        for (const preset of clockPresets) {
            if (p.left === preset.left && p.top === preset.top && p.right === preset.right && p.bottom === preset.bottom)
                return preset.id;
        }
        return "custom";
    }

    function applyClockPreset(id: string): void {
        const preset = clockPresets.find(p => p.id === id);
        if (!preset)
            return;
        GlobalConfig.background.desktopClock.position.left = preset.left;
        GlobalConfig.background.desktopClock.position.top = preset.top;
        GlobalConfig.background.desktopClock.position.right = preset.right;
        GlobalConfig.background.desktopClock.position.bottom = preset.bottom;
    }

    title: qsTr("Desktop & background")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Desktop clock
        SectionHeader {
            first: true
            text: qsTr("Desktop clock")
        }

        ToggleRow {
            first: true
            text: qsTr("Desktop clock")
            subtext: qsTr("Display clock widget directly on the desktop wallpaper")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            id: clockPosPreset

            label: qsTr("Clock position")
            subtext: qsTr("Choose a preset screen corner or edge")
            disabled: !Config.background.desktopClock.enabled
            fallbackText: qsTr("Custom")
            menuItems: clockPresetItems.instances
            onSelected: item => root.applyClockPreset(item.value)

            Binding {
                target: clockPosPreset
                property: "active"
                value: clockPresetItems.instances.find(i => i.value === root.currentClockPreset()) ?? null
            }

            Variants {
                id: clockPresetItems

                model: root.clockPresets

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            label: qsTr("Horizontal position (%)")
            subtext: qsTr("Distance from the left edge as a percentage of screen width")
            disabled: !Config.background.desktopClock.enabled
            value: Config.background.desktopClock.position.left >= 0
                ? Config.background.desktopClock.position.left
                : Math.max(0, 100 - Math.max(0, Config.background.desktopClock.position.right))
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => {
                GlobalConfig.background.desktopClock.position.left = v;
                GlobalConfig.background.desktopClock.position.right = -1;
            }
        }

        StepperRow {
            label: qsTr("Vertical position (%)")
            subtext: qsTr("Distance from the top edge as a percentage of screen height")
            disabled: !Config.background.desktopClock.enabled
            value: Config.background.desktopClock.position.top >= 0
                ? Config.background.desktopClock.position.top
                : Math.max(0, 100 - Math.max(0, Config.background.desktopClock.position.bottom))
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => {
                GlobalConfig.background.desktopClock.position.top = v;
                GlobalConfig.background.desktopClock.position.bottom = -1;
            }
        }

        StepperRow {
            last: true
            label: qsTr("Clock scale")
            subtext: qsTr("Size multiplier for the desktop clock")
            disabled: !Config.background.desktopClock.enabled
            value: Config.background.desktopClock.scale
            from: 0.5
            to: 2.0
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.desktopClock.scale = v
        }

        // Background audio visualiser
        SectionHeader {
            text: qsTr("Background audio visualiser")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Render live audio visualiser bars on the background")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            text: qsTr("Auto-hide")
            subtext: qsTr("Automatically hide visualiser when no audio is playing")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            text: qsTr("Blur effect")
            subtext: qsTr("Apply soft blur to background visualiser bars")
            disabled: !Config.background.visualiser.enabled
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            label: qsTr("Bar rounding")
            subtext: qsTr("Corner rounding multiplier for visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.rounding
            from: 0
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            last: true
            label: qsTr("Bar spacing")
            subtext: qsTr("Spacing multiplier between visualiser bars")
            disabled: !Config.background.visualiser.enabled
            value: Config.background.visualiser.spacing
            from: 0.5
            to: 5
            stepSize: 0.5
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }

        // Borders and rounding
        SectionHeader {
            text: qsTr("Borders & Rounding")
        }

        StepperRow {
            first: true
            label: qsTr("Border thickness")
            subtext: qsTr("Global border thickness (pixels)")
            value: Config.border.thickness
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            last: true
            label: qsTr("Corner rounding")
            subtext: qsTr("Global corner rounding radius (pixels)")
            value: Config.border.rounding
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = v
        }
    }
}
