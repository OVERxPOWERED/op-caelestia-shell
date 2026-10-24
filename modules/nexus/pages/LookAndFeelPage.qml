pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Everything about how the shell and windows look and feel, in one place. Each section is
// opt-in: the defaults keep the original look, and every change can be undone here.
PageBase {
    id: root

    readonly property var screens: Displays.monitors.filter(m => !m.disabled && !m.fallback && (Displays.treatVirtualAsExternal || !m.virtual))

    title: Tr.tr("Look & feel")

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Density")
        }

        // Same setting as Display > Interface size
        Repeater {
            model: root.screens

            InterfaceSizeRow {
                required property var modelData
                required property int index

                first: index === 0
                screenName: modelData.name
                showName: root.screens.length > 1
            }
        }

        SelectRow {
            id: presetRow

            label: Tr.tr("Window spacing")
            subtext: Tr.tr("Gaps between windows and the border around them")
            fallbackText: Tr.tr("Custom")
            menuItems: presetItems.instances
            onSelected: item => Density.setPreset(item.value)

            // Picking an item replaces a plain `active:` binding, so re-assert the real value
            Binding {
                target: presetRow
                property: "active"
                value: presetItems.instances.find(i => i.value === Density.preset) ?? null
            }

            Variants {
                id: presetItems

                model: [
                    {
                        id: "comfortable",
                        name: Tr.tr("Comfortable")
                    },
                    {
                        id: "compact",
                        name: Tr.tr("Compact")
                    },
                    {
                        id: "dense",
                        name: Tr.tr("Dense")
                    }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            id: inRow

            label: Tr.tr("Gap between windows")
            from: 0
            to: 30
            onMoved: v => Density.setValue("gapsIn", v)

            Binding {
                target: inRow
                property: "value"
                value: Density.gapsIn
            }
        }

        StepperRow {
            id: outRow

            label: Tr.tr("Gap around the screen")
            from: 0
            to: 40
            onMoved: v => Density.setValue("gapsOut", v)

            Binding {
                target: outRow
                property: "value"
                value: Density.gapsOut
            }
        }

        StepperRow {
            id: borderRow

            last: true
            label: Tr.tr("Window border")
            from: 0
            to: 8
            onMoved: v => Density.setValue("border", v)

            Binding {
                target: borderRow
                property: "value"
                value: Density.border
            }
        }

        SectionHeader {
            text: Tr.tr("Glass")
        }

        ToggleRow {
            id: blurRow

            first: true
            text: Tr.tr("Blur behind the overview")
            subtext: Tr.tr("Frosted glass instead of a plain dim backdrop")
            onToggled: Glass.setOverviewBlur(blurRow.checked)

            Binding {
                target: blurRow
                property: "checked"
                value: Glass.overviewBlur
            }
        }

        StepperRow {
            id: opacityRow

            label: Tr.tr("Window opacity")
            subtext: Tr.tr("How see-through app windows are (%1% is your config's value)").arg(Glass.basePercent)
            from: 50
            to: 100
            stepSize: 2
            onMoved: v => Glass.setWindowPercent(v)

            Binding {
                target: opacityRow
                property: "value"
                value: Glass.effectivePercent
            }
        }

        ToggleRow {
            id: solidRow

            text: Tr.tr("Solid text windows")
            subtext: Tr.tr("Browsers, editors, notes and document viewers stay fully opaque for easier reading")
            onToggled: Glass.setSolidText(solidRow.checked)

            Binding {
                target: solidRow
                property: "checked"
                value: Glass.solidText
            }
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset glass to defaults")
            subtext: Tr.tr("Back to the look from your config")
            disabled: Glass.isDefault
            onClicked: Glass.resetAll()
        }
    }
}
