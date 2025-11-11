pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    property bool showDebugInfo: false

    anchors.fill: parent

    spacing: 0

    FileView {
        id: configFile

        path: `${Paths.config}/shell.json`
        watchChanges: true

        onLoaded: {
            try {
                const config = JSON.parse(text());
                updateFromConfig(config);
            } catch (e) {
                console.error("Failed to parse config:", e);
            }
        }
    }

    function updateFromConfig(config) {
        // Update clock toggle
        if (config.bar && config.bar.clock) {
            clockShowIconSwitch.checked = config.bar.clock.showIcon !== false;
        }

        // Update entries
        if (config.bar && config.bar.entries) {
            entriesModel.clear();
            for (const entry of config.bar.entries) {
                entriesModel.append({
                    id: entry.id,
                    enabled: entry.enabled !== false
                });
            }
        }
    }

    function saveConfig(entryIndex, entryEnabled) {
        if (!configFile.loaded) {
            root.lastSaveStatus = "Error: Config file not loaded yet";
            root.debugInfo = "Config file not loaded yet, cannot save";
            return;
        }
        
        try {
            const config = JSON.parse(configFile.text());
            
            // Update clock setting (same simple approach - read directly from the switch)
            if (!config.bar) config.bar = {};
            if (!config.bar.clock) config.bar.clock = {};
            config.bar.clock.showIcon = clockShowIconSwitch.checked;

            // Update entries from the model (same approach as clock - use provided value if available)
            if (!config.bar.entries) config.bar.entries = [];
            config.bar.entries = [];
            
            let debugInfo = `saveConfig called\n`;
            debugInfo += `entryIndex: ${entryIndex}\n`;
            debugInfo += `entryEnabled: ${entryEnabled}\n`;
            debugInfo += `entriesModel.count: ${entriesModel.count}\n\n`;
            
            for (let i = 0; i < entriesModel.count; i++) {
                const entry = entriesModel.get(i);
                // If this is the entry being updated, use the provided value (same as clock toggle reads from switch)
                // Otherwise use the value from the model
                let enabled = entry.enabled;
                if (entryIndex !== undefined && i === entryIndex) {
                    enabled = entryEnabled;
                    debugInfo += `Entry ${i} (${entry.id}): Using provided value = ${entryEnabled}\n`;
                } else {
                    debugInfo += `Entry ${i} (${entry.id}): Using model value = ${entry.enabled}\n`;
                }
                config.bar.entries.push({
                    id: entry.id,
                    enabled: enabled
                });
            }

            debugInfo += `\nFinal entries array:\n${JSON.stringify(config.bar.entries, null, 2)}\n`;
            root.debugInfo = debugInfo;

            // Write back to file using setText (same simple approach that worked for clock)
            const jsonString = JSON.stringify(config, null, 4);
            configFile.setText(jsonString);
            root.lastSaveStatus = `Saved! Entries count: ${config.bar.entries.length}`;
        } catch (e) {
            root.lastSaveStatus = `Error: ${e.message}`;
            root.debugInfo = `Failed to save config:\n${e.message}\n${e.stack}`;
        }
    }

    ListModel {
        id: entriesModel
    }

    // Debug info
    property string debugInfo: ""
    property string lastSaveStatus: ""

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            spacing: Appearance.spacing.small

            RowLayout {
                spacing: Appearance.spacing.smaller

                StyledText {
                    text: qsTr("Settings")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Clock")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Clock display settings")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: clockRow.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                RowLayout {
                    id: clockRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Show clock icon")
                    }

                    StyledSwitch {
                        id: clockShowIconSwitch
                        checked: true
                        onToggled: {
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Taskbar Entries")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Enable or disable taskbar entries")
                color: Colours.palette.m3outline
            }

            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 0

                model: entriesModel
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    id: delegate
                    required property string id
                    required property bool enabled
                    required property int index

                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Colours.tPalette.m3surfaceContainer
                    radius: Appearance.rounding.normal

                    RowLayout {
                        id: entryRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: id.charAt(0).toUpperCase() + id.slice(1)
                            font.weight: enabled ? 500 : 400
                        }

                        StyledSwitch {
                            checked: enabled
                            onToggled: {
                                // Store the values in local variables to ensure they're accessible
                                // Access index from the delegate
                                const entryIndex = delegate.index;
                                const entryEnabled = checked;
                                console.log(`Entry toggle: index=${entryIndex}, checked=${entryEnabled}`);
                                // Update the model first
                                entriesModel.setProperty(entryIndex, "enabled", entryEnabled);
                                // Save immediately with the value directly (same technique as clock toggle)
                                // Clock toggle reads directly from clockShowIconSwitch.checked
                                // We pass the value directly here (same approach)
                                root.saveConfig(entryIndex, entryEnabled);
                            }
                        }
                    }

                    implicitHeight: entryRow.implicitHeight + Appearance.padding.normal * 2
                }
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2

            flickableDirection: Flickable.VerticalFlick
            contentHeight: contentLayout.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: parent
            }

            ColumnLayout {
                id: contentLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "task_alt"
                    font.pointSize: Appearance.font.size.extraLarge * 3
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Taskbar settings")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Clock")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: clockShowIconSwitch.checked ? qsTr("Clock icon enabled") : qsTr("Clock icon disabled")
                    color: Colours.palette.m3outline
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Taskbar Entries")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Configure which entries appear in the taskbar")
                    color: Colours.palette.m3outline
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.large
                    implicitHeight: debugToggleRow.implicitHeight + Appearance.padding.large * 2
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Appearance.rounding.normal

                    RowLayout {
                        id: debugToggleRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Show debug information")
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledSwitch {
                            id: showDebugInfoSwitch
                            checked: root.showDebugInfo
                            onToggled: {
                                root.showDebugInfo = checked;
                            }
                        }
                    }
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.showDebugInfo
                    text: qsTr("Debug Info")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    Layout.maximumHeight: 300
                    visible: root.showDebugInfo

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    clip: true

                    StyledFlickable {
                        id: debugFlickable
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        contentHeight: debugText.implicitHeight
                        clip: true

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: debugFlickable
                        }

                        TextEdit {
                            id: debugText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: parent.width

                            text: root.debugInfo || "No debug info yet"
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurface
                            wrapMode: TextEdit.Wrap
                            readOnly: true
                            selectByMouse: true
                            selectByKeyboard: true
                        }
                    }
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.small
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.showDebugInfo
                    text: root.lastSaveStatus || ""
                    font.pointSize: Appearance.font.size.small
                    color: root.lastSaveStatus.includes("Error") ? Colours.palette.m3error : Colours.palette.m3primary
                }
            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}

