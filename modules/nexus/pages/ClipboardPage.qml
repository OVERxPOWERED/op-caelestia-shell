pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Clipboard")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Display & Layout
        SectionHeader {
            first: true
            text: Tr.tr("Display & Layout")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Keyboard shortcuts guide")
            subtext: Tr.tr("Show keyboard shortcut hints at the bottom of the clipboard")
            checked: ClipboardSettings.showInstructions
            onToggled: {
                ClipboardSettings.showInstructions = checked;
                ClipboardSettings.save();
            }
        }

        ToggleRow {
            text: Tr.tr("Clear search on close")
            subtext: Tr.tr("Reset search query when closing the clipboard")
            checked: ClipboardSettings.autoClearSearch
            onToggled: {
                ClipboardSettings.autoClearSearch = checked;
                ClipboardSettings.save();
            }
        }

        ToggleRow {
            text: Tr.tr("Auto-focus search")
            subtext: Tr.tr("Automatically focus the search input field upon opening")
            checked: ClipboardSettings.autoFocusSearch
            onToggled: {
                ClipboardSettings.autoFocusSearch = checked;
                ClipboardSettings.save();
            }
        }

        SliderRow {
            last: true
            icon: "image"
            label: Tr.tr("Image card height")
            valueLabel: `${ClipboardSettings.imageCardHeight} px`
            value: (ClipboardSettings.imageCardHeight - 80) / 100
            onMoved: v => {
                ClipboardSettings.imageCardHeight = Math.round(80 + v * 100);
                ClipboardSettings.save();
            }
        }

        // History & Retention
        SectionHeader {
            text: Tr.tr("History & Storage")
        }

        SliderRow {
            first: true
            icon: "history"
            label: Tr.tr("History items loaded")
            valueLabel: `${ClipboardSettings.maxHistory} items`
            value: (ClipboardSettings.maxHistory - 20) / 180
            onMoved: v => {
                ClipboardSettings.maxHistory = Math.round(20 + v * 180);
                ClipboardSettings.save();
            }
        }

        RowButton {
            icon: "cached"
            text: Tr.tr("Clear thumbnail cache")
            subtext: Tr.tr("Purge all cached thumbnail images from ~/.cache/cliphist/thumbnails")
            onClicked: {
                ClipboardSettings.clearCache();
            }
        }

        RowButton {
            last: true
            icon: "delete_sweep"
            text: Tr.tr("Wipe clipboard history")
            subtext: Tr.tr("Permanently delete all stored history entries from cliphist")
            onClicked: {
                ClipboardSettings.wipeHistory();
            }
        }

        // Shortcuts
        SectionHeader {
            text: Tr.tr("Keyboard Shortcuts")
        }

        InfoRow {
            first: true
            icon: "keyboard"
            label: Tr.tr("Toggle clipboard")
            subtext: Tr.tr("Global keybinding to open/close native clipboard")
            value: "Super + V"
        }

        InfoRow {
            icon: "swap_vert"
            label: Tr.tr("Navigate list")
            subtext: Tr.tr("Move selection highlight up and down")
            value: "↑ / ↓"
        }

        InfoRow {
            icon: "keyboard_return"
            label: Tr.tr("Select & copy")
            subtext: Tr.tr("Copy selected item to clipboard and close")
            value: "Enter"
        }

        InfoRow {
            last: true
            icon: "close"
            label: Tr.tr("Close")
            subtext: Tr.tr("Clear search or dismiss clipboard window")
            value: "Escape"
        }
    }
}
