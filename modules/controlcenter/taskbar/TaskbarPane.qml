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
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    // Bar Behavior
    property bool persistent: Config.bar.persistent ?? true
    property bool showOnHover: Config.bar.showOnHover ?? true
    property int dragThreshold: Config.bar.dragThreshold ?? 20

    // Status Icons
    property bool showAudio: Config.bar.status.showAudio ?? true
    property bool showMicrophone: Config.bar.status.showMicrophone ?? true
    property bool showKbLayout: Config.bar.status.showKbLayout ?? false
    property bool showNetwork: Config.bar.status.showNetwork ?? true
    property bool showBluetooth: Config.bar.status.showBluetooth ?? true
    property bool showBattery: Config.bar.status.showBattery ?? true
    property bool showLockStatus: Config.bar.status.showLockStatus ?? true

    // Tray Settings
    property bool trayBackground: Config.bar.tray.background ?? false
    property bool trayCompact: Config.bar.tray.compact ?? false
    property bool trayRecolour: Config.bar.tray.recolour ?? false

    // Workspaces
    property int workspacesShown: Config.bar.workspaces.shown ?? 5
    property bool workspacesActiveIndicator: Config.bar.workspaces.activeIndicator ?? true
    property bool workspacesOccupiedBg: Config.bar.workspaces.occupiedBg ?? false
    property bool workspacesShowWindows: Config.bar.workspaces.showWindows ?? false
    property bool workspacesPerMonitor: Config.bar.workspaces.perMonitorWorkspaces ?? true

    anchors.fill: parent

    spacing: 0

    Component.onCompleted: {
        // Update clock toggle
        clockShowIconSwitch.checked = Config.bar.clock.showIcon ?? true;

        // Update entries
        if (Config.bar.entries) {
            entriesModel.clear();
            for (let i = 0; i < Config.bar.entries.length; i++) {
                const entry = Config.bar.entries[i];
                entriesModel.append({
                    id: entry.id,
                    enabled: entry.enabled !== false
                });
            }
        }
    }

    function saveConfig(entryIndex, entryEnabled) {
        // Update clock setting
        Config.bar.clock.showIcon = clockShowIconSwitch.checked;

        // Update bar behavior
        Config.bar.persistent = root.persistent;
        Config.bar.showOnHover = root.showOnHover;
        Config.bar.dragThreshold = root.dragThreshold;

        // Update status icons
        Config.bar.status.showAudio = root.showAudio;
        Config.bar.status.showMicrophone = root.showMicrophone;
        Config.bar.status.showKbLayout = root.showKbLayout;
        Config.bar.status.showNetwork = root.showNetwork;
        Config.bar.status.showBluetooth = root.showBluetooth;
        Config.bar.status.showBattery = root.showBattery;
        Config.bar.status.showLockStatus = root.showLockStatus;

        // Update tray settings
        Config.bar.tray.background = root.trayBackground;
        Config.bar.tray.compact = root.trayCompact;
        Config.bar.tray.recolour = root.trayRecolour;

        // Update workspaces
        Config.bar.workspaces.shown = root.workspacesShown;
        Config.bar.workspaces.activeIndicator = root.workspacesActiveIndicator;
        Config.bar.workspaces.occupiedBg = root.workspacesOccupiedBg;
        Config.bar.workspaces.showWindows = root.workspacesShowWindows;
        Config.bar.workspaces.perMonitorWorkspaces = root.workspacesPerMonitor;

        // Update entries from the model (same approach as clock - use provided value if available)
        const entries = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const entry = entriesModel.get(i);
            // If this is the entry being updated, use the provided value (same as clock toggle reads from switch)
            // Otherwise use the value from the model
            let enabled = entry.enabled;
            if (entryIndex !== undefined && i === entryIndex) {
                enabled = entryEnabled;
            }
            entries.push({
                id: entry.id,
                enabled: enabled
            });
        }
        Config.bar.entries = entries;
    }

    ListModel {
        id: entriesModel
    }


    function collapseAllSections(exceptSection) {
        if (exceptSection !== clockSection) clockSection.expanded = false;
        if (exceptSection !== barBehaviorSection) barBehaviorSection.expanded = false;
        if (exceptSection !== statusIconsSection) statusIconsSection.expanded = false;
        if (exceptSection !== traySettingsSection) traySettingsSection.expanded = false;
        if (exceptSection !== workspacesSection) workspacesSection.expanded = false;
    }

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        StyledFlickable {
            id: sidebarFlickable
            anchors.fill: parent
            flickableDirection: Flickable.VerticalFlick
            contentHeight: sidebarLayout.implicitHeight + Appearance.padding.large * 2
            clip: true

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: sidebarFlickable
            }

            ColumnLayout {
                id: sidebarLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
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

            CollapsibleSection {
                id: clockSection
                title: qsTr("Clock")
                description: qsTr("Clock display settings")
                onToggleRequested: {
                    root.collapseAllSections(clockSection);
                }

                RowLayout {
                    id: clockRow

                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.padding.large
                    Layout.rightMargin: Appearance.padding.large
                    Layout.alignment: Qt.AlignVCenter

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

            CollapsibleSection {
                id: barBehaviorSection
                title: qsTr("Bar Behavior")
                onToggleRequested: {
                    root.collapseAllSections(barBehaviorSection);
                }

                SwitchRow {
                    label: qsTr("Persistent")
                    checked: root.persistent
                    onToggled: checked => {
                        root.persistent = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show on hover")
                    checked: root.showOnHover
                    onToggled: checked => {
                        root.showOnHover = checked;
                        root.saveConfig();
                    }
                }

                SpinBoxRow {
                    label: qsTr("Drag threshold")
                    min: 0
                    max: 100
                    value: root.dragThreshold
                    onValueModified: value => {
                        root.dragThreshold = value;
                        root.saveConfig();
                    }
                }
            }

            CollapsibleSection {
                id: statusIconsSection
                title: qsTr("Status Icons")
                onToggleRequested: {
                    root.collapseAllSections(statusIconsSection);
                }

                SwitchRow {
                    label: qsTr("Show audio")
                    checked: root.showAudio
                    onToggled: checked => {
                        root.showAudio = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show microphone")
                    checked: root.showMicrophone
                    onToggled: checked => {
                        root.showMicrophone = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show keyboard layout")
                    checked: root.showKbLayout
                    onToggled: checked => {
                        root.showKbLayout = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show network")
                    checked: root.showNetwork
                    onToggled: checked => {
                        root.showNetwork = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show bluetooth")
                    checked: root.showBluetooth
                    onToggled: checked => {
                        root.showBluetooth = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show battery")
                    checked: root.showBattery
                    onToggled: checked => {
                        root.showBattery = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show lock status")
                    checked: root.showLockStatus
                    onToggled: checked => {
                        root.showLockStatus = checked;
                        root.saveConfig();
                    }
                }
            }

            CollapsibleSection {
                id: traySettingsSection
                title: qsTr("Tray Settings")
                onToggleRequested: {
                    root.collapseAllSections(traySettingsSection);
                }

                SwitchRow {
                    label: qsTr("Background")
                    checked: root.trayBackground
                    onToggled: checked => {
                        root.trayBackground = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Compact")
                    checked: root.trayCompact
                    onToggled: checked => {
                        root.trayCompact = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Recolour")
                    checked: root.trayRecolour
                    onToggled: checked => {
                        root.trayRecolour = checked;
                        root.saveConfig();
                    }
                }
            }

            CollapsibleSection {
                id: workspacesSection
                title: qsTr("Workspaces")
                onToggleRequested: {
                    root.collapseAllSections(workspacesSection);
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesShownRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesShownRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Shown")
                        }

                        CustomSpinBox {
                            min: 1
                            max: 20
                            value: root.workspacesShown
                            onValueModified: value => {
                                root.workspacesShown = value;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesActiveIndicatorRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesActiveIndicatorRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Active indicator")
                        }

                        StyledSwitch {
                            checked: root.workspacesActiveIndicator
                            onToggled: {
                                root.workspacesActiveIndicator = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesOccupiedBgRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesOccupiedBgRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Occupied background")
                        }

                        StyledSwitch {
                            checked: root.workspacesOccupiedBg
                            onToggled: {
                                root.workspacesOccupiedBg = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesShowWindowsRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesShowWindowsRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Show windows")
                        }

                        StyledSwitch {
                            checked: root.workspacesShowWindows
                            onToggled: {
                                root.workspacesShowWindows = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesPerMonitorRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesPerMonitorRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Per monitor workspaces")
                        }

                        StyledSwitch {
                            checked: root.workspacesPerMonitor
                            onToggled: {
                                root.workspacesPerMonitor = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }
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
            clip: true

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
                    text: qsTr("Taskbar Settings")
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

            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}
