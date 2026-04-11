pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

ColumnLayout {
    id: root

    required property Session session

    spacing: Tokens.spacing.normal

    SettingsHeader {
        icon: "apps"
        title: qsTr("Launcher Settings")
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("General")
        description: qsTr("General launcher settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("Enabled")
            checked: Config.launcher.enabled
            toggle.onToggled: {
                Config.launcher.enabled = checked;
            }
        }

        ToggleRow {
            label: qsTr("Show on hover")
            checked: Config.launcher.showOnHover
            toggle.onToggled: {
                Config.launcher.showOnHover = checked;
            }
        }

        ToggleRow {
            label: qsTr("Vim keybinds")
            checked: Config.launcher.vimKeybinds
            toggle.onToggled: {
                Config.launcher.vimKeybinds = checked;
            }
        }

        ToggleRow {
            label: qsTr("Enable dangerous actions")
            checked: Config.launcher.enableDangerousActions
            toggle.onToggled: {
                Config.launcher.enableDangerousActions = checked;
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Display")
        description: qsTr("Display and appearance settings")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.small / 2

        PropertyRow {
            label: qsTr("Max shown items")
            value: qsTr("%1").arg(Config.launcher.maxShown)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Max wallpapers")
            value: qsTr("%1").arg(Config.launcher.maxWallpapers)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Drag threshold")
            value: qsTr("%1 px").arg(Config.launcher.dragThreshold)
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Prefixes")
        description: qsTr("Command prefix settings")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.small / 2

        PropertyRow {
            label: qsTr("Special prefix")
            value: Config.launcher.specialPrefix || qsTr("None")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Action prefix")
            value: Config.launcher.actionPrefix || qsTr("None")
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Fuzzy search")
        description: qsTr("Fuzzy search settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("Apps")
            checked: Config.launcher.useFuzzy.apps
            toggle.onToggled: {
                Config.launcher.useFuzzy.apps = checked;
            }
        }

        ToggleRow {
            label: qsTr("Actions")
            checked: Config.launcher.useFuzzy.actions
            toggle.onToggled: {
                Config.launcher.useFuzzy.actions = checked;
            }
        }

        ToggleRow {
            label: qsTr("Schemes")
            checked: Config.launcher.useFuzzy.schemes
            toggle.onToggled: {
                Config.launcher.useFuzzy.schemes = checked;
            }
        }

        ToggleRow {
            label: qsTr("Variants")
            checked: Config.launcher.useFuzzy.variants
            toggle.onToggled: {
                Config.launcher.useFuzzy.variants = checked;
            }
        }

        ToggleRow {
            label: qsTr("Wallpapers")
            checked: Config.launcher.useFuzzy.wallpapers
            toggle.onToggled: {
                Config.launcher.useFuzzy.wallpapers = checked;
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Sizes")
        description: qsTr("Size settings for launcher items")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.small / 2

        PropertyRow {
            label: qsTr("Item width")
            value: qsTr("%1 px").arg(Tokens.sizes.launcher.itemWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Item height")
            value: qsTr("%1 px").arg(Tokens.sizes.launcher.itemHeight)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Wallpaper width")
            value: qsTr("%1 px").arg(Tokens.sizes.launcher.wallpaperWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Wallpaper height")
            value: qsTr("%1 px").arg(Tokens.sizes.launcher.wallpaperHeight)
        }
    }

    SectionHeader {
        Layout.topMargin: Tokens.spacing.large
        title: qsTr("Hidden apps")
        description: qsTr("Applications hidden from launcher")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.small / 2

        PropertyRow {
            label: qsTr("Total hidden")
            value: qsTr("%1").arg(Config.launcher.hiddenApps ? Config.launcher.hiddenApps.length : 0)
        }
    }
}
