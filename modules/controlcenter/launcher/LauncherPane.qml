pragma ComponentBehavior: Bound

import ".."
import "../../launcher/services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    property var selectedApp: null
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
                updateToggleState();
            } catch (e) {
                console.error("Failed to parse config:", e);
            }
        }
    }

    function updateToggleState() {
        if (!root.selectedApp || !configFile.loaded) {
            hideFromLauncherSwitch.checked = false;
            return;
        }

        try {
            const config = JSON.parse(configFile.text());
            const appId = root.selectedApp.id || root.selectedApp.entry?.id;
            
            if (config.launcher && config.launcher.hiddenApps) {
                hideFromLauncherSwitch.checked = config.launcher.hiddenApps.includes(appId);
            } else {
                hideFromLauncherSwitch.checked = false;
            }
        } catch (e) {
            console.error("Failed to update toggle state:", e);
        }
    }

    function saveHiddenApps() {
        if (!configFile.loaded || !root.selectedApp) {
            return;
        }

        try {
            const config = JSON.parse(configFile.text());
            const appId = root.selectedApp.id || root.selectedApp.entry?.id;
            
            if (!config.launcher) config.launcher = {};
            if (!config.launcher.hiddenApps) config.launcher.hiddenApps = [];
            
            const hiddenApps = config.launcher.hiddenApps;
            const isHidden = hideFromLauncherSwitch.checked;
            
            if (isHidden) {
                // Add to hiddenApps if not already there
                if (!hiddenApps.includes(appId)) {
                    hiddenApps.push(appId);
                }
            } else {
                // Remove from hiddenApps
                const index = hiddenApps.indexOf(appId);
                if (index !== -1) {
                    hiddenApps.splice(index, 1);
                }
            }
            
            const jsonString = JSON.stringify(config, null, 4);
            configFile.setText(jsonString);
        } catch (e) {
            console.error("Failed to save config:", e);
        }
    }

    onSelectedAppChanged: {
        updateToggleState();
    }

    AppDb {
        id: allAppsDb

        path: `${Paths.state}/apps.sqlite`
        entries: DesktopEntries.applications.values  // No filter - show all apps
    }

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
                text: qsTr("Applications (%1)").arg(allAppsDb.apps.length)
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("All applications available in the launcher")
                color: Colours.palette.m3outline
            }

            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Appearance.spacing.normal

                model: allAppsDb.apps
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property var modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    readonly property bool isSelected: root.selectedApp === modelData

                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isSelected ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isSelected ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            root.selectedApp = modelData;
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        IconImage {
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: 32
                            source: {
                                const entry = modelData.entry;
                                return entry ? Quickshell.iconPath(entry.icon, "image-missing") : "image-missing";
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.entry?.name || qsTr("Unknown")
                            font.pointSize: Appearance.font.size.normal
                        }
                    }

                    implicitHeight: 40
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2

            spacing: Appearance.spacing.normal

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: iconLoader.implicitWidth
                implicitHeight: iconLoader.implicitHeight

                Loader {
                    id: iconLoader
                    sourceComponent: root.selectedApp ? appIconComponent : defaultIconComponent
                }

                Component {
                    id: appIconComponent
                    IconImage {
                        implicitSize: Appearance.font.size.extraLarge * 3 * 2
                        source: {
                            if (!root.selectedApp) return "image-missing";
                            const entry = root.selectedApp.entry;
                            if (entry && entry.icon) {
                                return Quickshell.iconPath(entry.icon, "image-missing");
                            }
                            return "image-missing";
                        }
                    }
                }

                Component {
                    id: defaultIconComponent
                    MaterialIcon {
                        text: "apps"
                        font.pointSize: Appearance.font.size.extraLarge * 3
                        font.bold: true
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.selectedApp ? (root.selectedApp.name || root.selectedApp.entry?.name || qsTr("Application Details")) : qsTr("Launcher Applications")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Appearance.spacing.large

                StyledFlickable {
                    anchors.fill: parent
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: debugLayout.implicitHeight

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: parent
                    }

                    ColumnLayout {
                        id: debugLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.normal
                            implicitHeight: hideToggleRow.implicitHeight + Appearance.padding.large * 2
                            color: Colours.tPalette.m3surfaceContainer
                            radius: Appearance.rounding.normal

                            RowLayout {
                                id: hideToggleRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Appearance.padding.large
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Hide from launcher")
                                    font.pointSize: Appearance.font.size.normal
                                }

                                StyledSwitch {
                                    id: hideFromLauncherSwitch
                                    checked: false
                                    enabled: root.selectedApp !== null && configFile.loaded
                                    onToggled: {
                                        root.saveHiddenApps();
                                    }
                                }
                            }
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.normal
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

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.normal
                            Layout.preferredHeight: 300
                            visible: root.showDebugInfo
                            color: Colours.tPalette.m3surfaceContainer
                            radius: Appearance.rounding.normal
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("Debug Info - All Available Properties")
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 500
                                }

                                StyledFlickable {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    flickableDirection: Flickable.VerticalFlick
                                    contentHeight: debugText.implicitHeight
                                    clip: true

                                    StyledScrollBar.vertical: StyledScrollBar {
                                        flickable: parent
                                    }

                                    TextEdit {
                                        id: debugText
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        width: parent.width

                                        text: {
                                            if (!root.selectedApp) return "No app selected";
                                            
                                            let debug = "";
                                            const app = root.selectedApp;
                                            const entry = app.entry;
                                            
                                            debug += "=== App Properties ===\n";
                                            for (let prop in app) {
                                                try {
                                                    const value = app[prop];
                                                    debug += prop + ": " + (value !== null && value !== undefined ? String(value) : "null/undefined") + "\n";
                                                } catch (e) {
                                                    debug += prop + ": [error accessing]\n";
                                                }
                                            }
                                            
                                            debug += "\n=== Entry Properties ===\n";
                                            if (entry) {
                                                for (let prop in entry) {
                                                    try {
                                                        const value = entry[prop];
                                                        debug += prop + ": " + (value !== null && value !== undefined ? String(value) : "null/undefined") + "\n";
                                                    } catch (e) {
                                                        debug += prop + ": [error accessing]\n";
                                                    }
                                                }
                                            } else {
                                                debug += "entry is null\n";
                                            }
                                            
                                            return debug;
                                        }
                                        font.pointSize: Appearance.font.size.small
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: TextEdit.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        selectByKeyboard: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}
