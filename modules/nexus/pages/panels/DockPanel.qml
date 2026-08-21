pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dock")
    isSubPage: true

    function getAppName(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.name ?? appId;
    }

    function getAppIcon(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.icon ?? "application-x-executable";
    }

    function removePinnedApp(index: int): void {
        const list = [...GlobalConfig.dock.pinnedApps];
        list.splice(index, 1);
        GlobalConfig.dock.pinnedApps = list;
    }

    function addPinnedApp(appId: string): void {
        const list = [...GlobalConfig.dock.pinnedApps];
        if (!list.includes(appId)) {
            list.push(appId);
            GlobalConfig.dock.pinnedApps = list;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the application dock at the bottom of the screen")
            checked: Config.dock.enabled
            onToggled: GlobalConfig.dock.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Show on hover")
            subtext: Config.dock.showOnHover ? qsTr("Reveal dock on hover (launcher opens on drag)") : qsTr("Reveal dock on drag (launcher opens on hover)")
            checked: Config.dock.showOnHover
            onToggled: {
                GlobalConfig.dock.showOnHover = checked;
                GlobalConfig.launcher.showOnHover = !checked;
            }
        }

        // Behaviour & Dimensions
        SectionHeader {
            text: qsTr("Behaviour & Sizing")
        }

        StepperRow {
            first: true
            label: qsTr("Maximum slots")
            subtext: qsTr("Max visible app slots before overflow scrolling")
            value: Config.dock.maxSlots
            from: 3
            to: 30
            stepSize: 1
            onMoved: v => GlobalConfig.dock.maxSlots = v
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the dock reveals")
            value: Config.dock.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dock.dragThreshold = v
        }

        // Pinned Applications
        SectionHeader {
            text: qsTr("Pinned applications")
        }

        Repeater {
            model: ScriptModel {
                values: GlobalConfig.dock.pinnedApps
            }

            ConnectedRect {
                id: pinnedRow

                required property string modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: false
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    IconImage {
                        source: Icons.getIcon(root.getAppIcon(pinnedRow.modelData))
                        implicitWidth: 24
                        implicitHeight: 24
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.getAppName(pinnedRow.modelData)
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.removePinnedApp(pinnedRow.index)
                    }
                }
            }
        }

        DialogSelectButton {
            id: addAppContainer

            rootParent: root.flickable
            icon: "add"
            label: qsTr("Pin an app")
            header: qsTr("Choose application to pin")
            acceptLabel: qsTr("Pin")

            model: {
                const apps = [...DesktopEntries.applications.values]
                    .filter(a => a.id && a.name && !GlobalConfig.dock.pinnedApps.includes(a.id))
                    .sort((a, b) => a.name.localeCompare(b.name))
                    .map(a => ({
                        id: a.id,
                        label: a.name
                    }));
                return apps;
            }

            onAccepted: {
                if (selectedItem)
                    root.addPinnedApp(selectedItem);
            }
        }
    }
}
