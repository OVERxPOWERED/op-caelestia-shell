pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var builtinToggles: ({
        wifi: Tr.tr("Wi-Fi"),
        bluetooth: Tr.tr("Bluetooth"),
        mic: Tr.tr("Microphone"),
        settings: Tr.tr("Settings"),
        gameMode: Tr.tr("Game mode"),
        dnd: Tr.tr("Do not disturb"),
        nightMode: Tr.tr("Night mode"),
        wallpaper: Tr.tr("Wallpaper selector"),
        focus: Tr.tr("Focus timer"),
        vpn: Tr.tr("VPN")
    })

    title: Tr.tr("Utilities")
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
            last: true
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("Show the utilities panel")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        // Cards
        SectionHeader {
            text: Tr.tr("Cards")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Keep awake")
            subtext: Tr.tr("Show the idle inhibitor card")
            checked: Config.utilities.cards.keepAwake
            onToggled: GlobalConfig.utilities.cards.keepAwake = checked
        }

        ToggleRow {
            text: Tr.tr("Screen recorder")
            subtext: Tr.tr("Show the screen recorder card")
            checked: Config.utilities.cards.recorder
            onToggled: GlobalConfig.utilities.cards.recorder = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Quick toggles")
            subtext: Tr.tr("Show the quick toggles card")
            checked: Config.utilities.cards.quickToggles
            onToggled: GlobalConfig.utilities.cards.quickToggles = checked
        }

        // Quick toggles
        SectionHeader {
            text: Tr.tr("Quick toggles")
        }

        ListEditor {
            function labelFor(item: var): string {
                const prettyName = root.builtinToggles[item.id];
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
            values: Config.utilities.quickToggles.values
            onItemMoved: (from, to) => GlobalConfig.utilities.quickToggles.move(from, to)
            onItemRemoved: index => GlobalConfig.utilities.quickToggles.remove(index)
            onItemToggled: (index, checked) => {
                GlobalConfig.utilities.quickToggles.at(index).enabled = checked;
            }
        }

        DialogSelectButton {
            id: addItemContainer

            rootParent: root.flickable
            icon: "add"
            label: Tr.tr("Add entry")
            header: Tr.tr("Add new entry")
            acceptLabel: Tr.trCtx("Add", "button")

            model: {
                const builtins = Object.keys(root.builtinToggles).map(k => ({
                    id: k,
                    label: root.builtinToggles[k]
                }));
                return builtins.filter(b => !Config.utilities.quickToggles.values.some(v => v.id === b.id));
            }

            onAccepted: {
                if (!selectedItem)
                    return;

                GlobalConfig.utilities.quickToggles.insert({
                    id: selectedItem,
                    enabled: true
                });
            }
        }

        // Night mode
        SectionHeader {
            visible: HyprSunset.available
            text: Tr.tr("Night mode")
        }

        SliderRow {
            readonly property int minTemp: 1000
            readonly property int maxTemp: 6500

            visible: HyprSunset.available
            first: true
            last: true
            icon: "dark_mode"
            label: Tr.tr("Color temperature")
            valueLabel: Tr.tr("%1K").arg(HyprSunset.temperature)
            value: (HyprSunset.temperature - minTemp) / (maxTemp - minTemp)
            onMoved: v => {
                const temp = Math.round(minTemp + v * (maxTemp - minTemp));
                HyprSunset.start(temp);
            }
        }
    }
}
