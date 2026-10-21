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

PageBase {
    id: root

    readonly property var mon: Displays.selectedMonitor
    readonly property var others: Displays.monitors.filter(m => m.name !== mon?.name && !m.disabled)
    readonly property var resolutions: {
        const seen = [];
        for (const m of mon?.modes ?? []) {
            const res = m.split("@")[0];
            if (!seen.includes(res))
                seen.push(res);
        }
        return seen;
    }
    readonly property string currentResolution: mon ? `${mon.width}x${mon.height}` : ""
    readonly property var refreshRates: (mon?.modes ?? []).filter(m => m.startsWith(currentResolution + "@")).map(m => m.split("@")[1])
    readonly property var scales: [0.75, 1, 1.25, 1.5, 1.75, 2]
    readonly property var rotations: [
        {
            text: Tr.tr("Normal"),
            value: 0
        },
        {
            text: Tr.tr("90°"),
            value: 1
        },
        {
            text: Tr.tr("180°"),
            value: 2
        },
        {
            text: Tr.tr("270°"),
            value: 3
        }
    ]

    function monitorLabel(m: var): string {
        return m.description ? `${m.name} · ${m.description}` : m.name;
    }

    title: Tr.tr("Display")

    Component.onCompleted: {
        Displays.refresh();
        Displays.reloadProfiles();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Keep or revert the change that was just made
        ConnectedRect {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            visible: Displays.pending
            first: true
            last: true
            color: Colours.palette.m3secondaryContainer
            implicitHeight: confirmRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: confirmRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Tr.tr("Keep these display settings?")
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        text: Tr.tr("Reverting in %1 s").arg(Displays.countdown)
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.label.medium
                    }
                }

                TextButton {
                    text: Tr.tr("Revert")
                    type: TextButton.Text
                    onClicked: Displays.revert()
                }

                TextButton {
                    text: Tr.tr("Keep")
                    type: TextButton.Filled
                    onClicked: Displays.keep()
                }
            }
        }

        SectionHeader {
            first: !Displays.pending
            text: Tr.tr("Layout")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: layoutCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: layoutCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: [
                            {
                                kind: "extend",
                                icon: "splitscreen_left",
                                text: Tr.tr("Extend")
                            },
                            {
                                kind: "mirror",
                                icon: "cast",
                                text: Tr.tr("Mirror")
                            },
                            {
                                kind: "external",
                                icon: "desktop_windows",
                                text: Tr.tr("External only")
                            },
                            {
                                kind: "laptop",
                                icon: "laptop",
                                text: Tr.tr("Laptop only")
                            }
                        ]

                        IconTextButton {
                            required property var modelData

                            icon: modelData.icon
                            text: modelData.text
                            type: IconTextButton.Tonal
                            disabled: !Displays.canChangeLayout
                            onClicked: Displays.layout(modelData.kind)
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !Displays.canChangeLayout
                    text: Tr.tr("Connect another display to choose how it is used")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Arrangement")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: arrangeCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: arrangeCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                DisplayArrangement {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    monitors: Displays.monitors
                    selected: root.mon?.name ?? ""
                    onSelectRequested: name => Displays.selected = name
                    onMoveRequested: (name, x, y) => Displays.setPosition(name, x, y)
                }

                // Every display, including ones that are turned off
                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: Displays.monitors

                        StyledRect {
                            id: chip

                            required property var modelData
                            readonly property bool isSelected: modelData.name === root.mon?.name

                            implicitWidth: chipLabel.implicitWidth + Tokens.padding.large * 2
                            implicitHeight: chipLabel.implicitHeight + Tokens.padding.small * 2
                            radius: Tokens.rounding.full
                            color: isSelected ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 3)

                            StateLayer {
                                onClicked: Displays.selected = chip.modelData.name
                            }

                            StyledText {
                                id: chipLabel

                                anchors.centerIn: parent
                                text: chip.modelData.disabled ? Tr.tr("%1 (off)").arg(chip.modelData.name) : chip.modelData.name
                                color: chip.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }
            }
        }

        // Settings of the selected display
        SectionHeader {
            visible: root.mon !== null
            text: root.mon ? root.monitorLabel(root.mon) : ""
        }

        ToggleRow {
            visible: root.mon !== null
            first: true
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Turn this display on or off")
            checked: !(root.mon?.disabled ?? false)
            onToggled: Displays.setEnabled(root.mon.name, checked)
        }

        SelectRow {
            visible: root.mon !== null && !root.mon.disabled
            label: Tr.tr("Resolution")
            active: resItems.instances.find(i => i.res === root.currentResolution) ?? null
            fallbackText: root.currentResolution
            menuItems: resItems.instances
            onSelected: item => {
                const best = root.mon.modes.find(m => m.startsWith(item.res + "@"));
                if (best)
                    Displays.setMode(root.mon.name, best);
            }

            Variants {
                id: resItems

                model: root.resolutions

                MenuItem {
                    required property string modelData
                    readonly property string res: modelData

                    text: modelData.replace("x", " × ")
                }
            }
        }

        SelectRow {
            visible: root.mon !== null && !root.mon.disabled
            label: Tr.tr("Refresh rate")
            active: rateItems.instances.find(i => i.rate === root.mon.refresh.toFixed(2)) ?? null
            fallbackText: `${root.mon?.refresh.toFixed(2)} Hz`
            menuItems: rateItems.instances
            onSelected: item => Displays.setMode(root.mon.name, `${root.currentResolution}@${item.rate}`)

            Variants {
                id: rateItems

                model: root.refreshRates

                MenuItem {
                    required property string modelData
                    readonly property string rate: modelData

                    text: Tr.tr("%1 Hz").arg(modelData)
                }
            }
        }

        SelectRow {
            visible: root.mon !== null && !root.mon.disabled
            label: Tr.tr("Scale")
            subtext: Tr.tr("Makes everything on this display larger or smaller")
            active: scaleItems.instances.find(i => Math.abs(i.value - root.mon.scale) < 0.01) ?? null
            fallbackText: `${Math.round((root.mon?.scale ?? 1) * 100)}%`
            menuItems: scaleItems.instances
            onSelected: item => Displays.setScale(root.mon.name, item.value)

            Variants {
                id: scaleItems

                model: root.scales

                MenuItem {
                    required property real modelData

                    text: `${Math.round(modelData * 100)}%`
                    value: modelData
                }
            }
        }

        SelectRow {
            visible: root.mon !== null && !root.mon.disabled
            label: Tr.tr("Rotation")
            active: rotItems.instances.find(i => i.value === root.mon.transform) ?? null
            fallbackText: Tr.tr("Custom")
            menuItems: rotItems.instances
            onSelected: item => Displays.setTransform(root.mon.name, item.value)

            Variants {
                id: rotItems

                model: root.rotations

                MenuItem {
                    required property var modelData

                    text: modelData.text
                    value: modelData.value
                }
            }
        }

        SelectRow {
            visible: root.mon !== null && !root.mon.disabled && root.others.length > 0
            label: Tr.tr("Mirror")
            subtext: Tr.tr("Show the same picture as another display")
            active: mirrorItems.instances.find(i => i.target === (root.mon.mirrorOf ?? "")) ?? null
            fallbackText: Tr.tr("Off")
            menuItems: mirrorItems.instances
            onSelected: item => Displays.setMirror(root.mon.name, item.target)

            Variants {
                id: mirrorItems

                model: ["", ...root.others.map(m => m.name)]

                MenuItem {
                    required property string modelData
                    readonly property string target: modelData

                    text: modelData === "" ? Tr.tr("Off") : modelData
                }
            }
        }

        StepperRow {
            visible: root.mon !== null && !root.mon.disabled && !root.mon.mirrorOf
            label: Tr.tr("Position X")
            subtext: Tr.tr("Distance from the left edge of the layout (pixels)")
            from: -16000
            to: 16000
            stepSize: 10
            value: root.mon?.x ?? 0
            onMoved: v => Displays.setPosition(root.mon.name, Math.round(v), root.mon.y)
        }

        StepperRow {
            visible: root.mon !== null && !root.mon.disabled && !root.mon.mirrorOf
            last: true
            label: Tr.tr("Position Y")
            subtext: Tr.tr("Distance from the top edge of the layout (pixels)")
            from: -16000
            to: 16000
            stepSize: 10
            value: root.mon?.y ?? 0
            onMoved: v => Displays.setPosition(root.mon.name, root.mon.x, Math.round(v))
        }

        // Saved layouts, shared with the hyprmoncfg terminal tool
        SectionHeader {
            text: Tr.tr("Profiles")
        }

        Repeater {
            model: Displays.userProfiles

            RowButton {
                id: profileRow

                required property var modelData
                required property int index

                first: index === 0
                icon: "bookmark"
                text: modelData.name
                subtext: modelData.outputs.map(o => o.name).join(" · ")
                trailingIcon: "play_arrow"
                onClicked: Displays.applyProfile(modelData)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            visible: Displays.userProfiles.length === 0
            text: Tr.tr("No saved profiles yet")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }

        TextFieldRow {
            first: Displays.userProfiles.length === 0
            last: true
            label: Tr.tr("Save current layout")
            subtext: Tr.tr("Type a name and press Enter")
            placeholderText: Tr.tr("Profile name")
            onEditingFinished: value => {
                if (value.trim()) {
                    Displays.saveProfile(value);
                    field.clear();
                }
            }
        }
    }
}
