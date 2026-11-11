pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.filedialog
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

        SectionHeader {
            text: Tr.tr("Motion")
        }

        SelectRow {
            id: speedRow

            first: true
            label: Tr.tr("Animation speed")
            subtext: Tr.tr("How fast the shell and your windows animate, together")
            fallbackText: `${Motion.speed.toFixed(2)}×`
            menuItems: speedItems.instances
            onSelected: item => Motion.setSpeed(item.value)

            // Picking an item replaces a plain `active:` binding, so re-assert the real value
            Binding {
                target: speedRow
                property: "active"
                value: speedItems.instances.find(i => Math.abs(i.value - Motion.speed) < 0.001) ?? null
            }

            Variants {
                id: speedItems

                model: [
                    {
                        name: Tr.tr("Calm"),
                        factor: 1.3
                    },
                    {
                        name: Tr.tr("Standard"),
                        factor: 1
                    },
                    {
                        name: Tr.tr("Snappy"),
                        factor: 0.75
                    },
                    {
                        name: Tr.tr("Quick"),
                        factor: 0.5
                    }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.factor
                }
            }
        }

        ToggleRow {
            id: matchRow

            text: Tr.tr("Windows move like the shell")
            subtext: Tr.tr("Windows, workspaces and panels share one set of curves and timings")
            onToggled: Motion.setMatchShell(matchRow.checked)

            Binding {
                target: matchRow
                property: "checked"
                value: Motion.matchShell
            }
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset motion to defaults")
            subtext: Tr.tr("Back to the timings from your config")
            disabled: Motion.isDefault
            onClicked: Motion.resetAll()
        }

        SectionHeader {
            text: Tr.tr("App fonts")
        }

        ToggleRow {
            id: fontsRow

            first: true
            text: Tr.tr("Use these fonts in apps")
            subtext: AppFonts.enabled ? Tr.tr("Apps pick this up the next time they start") : Tr.tr("Apps currently use %1 and %2 by default").arg(AppFonts.nowSans).arg(AppFonts.nowMono)
            onToggled: AppFonts.turn(fontsRow.checked)

            Binding {
                target: fontsRow
                property: "checked"
                value: AppFonts.enabled
            }
        }

        SelectRow {
            id: sansRow

            label: Tr.tr("Sans-serif font")
            subtext: Tr.tr("Text in browsers, Qt and most other apps")
            disabled: !AppFonts.enabled || AppFonts.busy
            fallbackText: AppFonts.sans
            menuItems: sansItems.instances
            onSelected: item => AppFonts.choose(item.value, AppFonts.mono)

            Binding {
                target: sansRow
                property: "active"
                value: sansItems.instances.find(i => i.value === AppFonts.sans) ?? null
            }

            Variants {
                id: sansItems

                model: AppFonts.sansChoices

                MenuItem {
                    required property string modelData

                    text: modelData
                    value: modelData
                }
            }
        }

        SelectRow {
            id: monoRow

            label: Tr.tr("Monospace font")
            subtext: Tr.tr("Code and terminal-style text")
            disabled: !AppFonts.enabled || AppFonts.busy
            fallbackText: AppFonts.mono
            menuItems: monoItems.instances
            onSelected: item => AppFonts.choose(AppFonts.sans, item.value)

            Binding {
                target: monoRow
                property: "active"
                value: monoItems.instances.find(i => i.value === AppFonts.mono) ?? null
            }

            Variants {
                id: monoItems

                model: AppFonts.monoChoices

                MenuItem {
                    required property string modelData

                    text: modelData
                    value: modelData
                }
            }
        }

        StepperRow {
            id: textSizeRow

            label: Tr.tr("Text size")
            subtext: Tr.tr("Fonts are scaled to read like the default ones (×%1 for the sans font, ×%2 for the monospace font). Change this to taste, in %").arg(AppFonts.autoSans.toFixed(2)).arg(AppFonts.autoMono.toFixed(2))
            disabled: !AppFonts.enabled
            from: 70
            to: 160
            stepSize: 5
            onMoved: v => AppFonts.setSizeAdjust(v)

            Binding {
                target: textSizeRow
                property: "value"
                value: AppFonts.sizeAdjust
            }
        }

        RowButton {
            visible: AppFonts.needsRestart
            icon: "restart_alt"
            text: Tr.tr("Restart the shell to use your new font")
            subtext: Tr.tr("The shell only sees fonts that were installed when it started. Until then it shows another font")
            onClicked: AppFonts.restartShell()
        }

        ToggleRow {
            id: shellFontRow

            text: Tr.tr("Also use them in the shell")
            subtext: Tr.tr("The bar, panels and Nexus too. Icons keep their own font")
            disabled: !AppFonts.enabled
            onToggled: AppFonts.setShellToo(shellFontRow.checked)

            Binding {
                target: shellFontRow
                property: "checked"
                value: AppFonts.shellToo && AppFonts.enabled
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: preview.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: preview

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("The quick brown fox jumps over the lazy dog")
                    font.family: AppFonts.sans
                    font.pixelSize: 18
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "0123456789  {}[]()  <= != =>  fn main() {}"
                    color: Colours.palette.m3onSurfaceVariant
                    font.family: AppFonts.mono
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }
        }

        RowButton {
            last: AppFonts.added.length === 0
            icon: "upload_file"
            text: AppFonts.busy ? Tr.tr("Working…") : Tr.tr("Add a font…")
            subtext: AppFonts.message || Tr.tr("Pick a .ttf, .otf or .ttc file. It is copied to your own fonts folder")
            disabled: AppFonts.busy
            onClicked: addFontDialog.open()

            FileDialog {
                id: addFontDialog

                title: Tr.tr("Choose a font file")
                filterLabel: Tr.tr("Font files")
                filters: ["ttf", "otf", "ttc"]
                onAccepted: path => AppFonts.addFont(path)
            }
        }

        Repeater {
            model: AppFonts.added

            RowButton {
                id: fontItem

                required property var modelData
                required property int index
                property bool armed

                last: index === AppFonts.added.length - 1
                icon: "font_download"
                text: modelData.family
                subtext: armed ? Tr.tr("Press again to remove %1").arg(modelData.file) : modelData.file
                trailingIcon: armed ? "delete_forever" : "delete"
                disabled: AppFonts.busy
                onClicked: {
                    if (!armed) {
                        armed = true;
                        return;
                    }
                    armed = false;
                    AppFonts.removeFont(modelData.file);
                }

                Timer {
                    running: fontItem.armed
                    interval: 4000
                    onTriggered: fontItem.armed = false
                }
            }
        }
    }
}
