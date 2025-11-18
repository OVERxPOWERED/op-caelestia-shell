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
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    // Clock
    property bool clockShowIcon: Config.bar.clock.showIcon ?? true

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

    // Scroll Actions
    property bool scrollWorkspaces: Config.bar.scrollActions.workspaces ?? true
    property bool scrollVolume: Config.bar.scrollActions.volume ?? true
    property bool scrollBrightness: Config.bar.scrollActions.brightness ?? true

    // Popouts
    property bool popoutActiveWindow: Config.bar.popouts.activeWindow ?? true
    property bool popoutTray: Config.bar.popouts.tray ?? true
    property bool popoutStatusIcons: Config.bar.popouts.statusIcons ?? true

    anchors.fill: parent

    Component.onCompleted: {
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
        Config.bar.clock.showIcon = root.clockShowIcon;

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

        // Update scroll actions
        Config.bar.scrollActions.workspaces = root.scrollWorkspaces;
        Config.bar.scrollActions.volume = root.scrollVolume;
        Config.bar.scrollActions.brightness = root.scrollBrightness;

        // Update popouts
        Config.bar.popouts.activeWindow = root.popoutActiveWindow;
        Config.bar.popouts.tray = root.popoutTray;
        Config.bar.popouts.statusIcons = root.popoutStatusIcons;

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

        // Persist changes to disk
        Config.save();
    }

    ListModel {
        id: entriesModel
    }

    ClippingRectangle {
        id: taskbarClippingRect
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.normal / 2

        radius: taskbarBorder.innerRadius
        color: "transparent"

        Loader {
            id: taskbarLoader

            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            asynchronous: true
            sourceComponent: taskbarContentComponent
        }
    }

    InnerBorder {
        id: taskbarBorder
        leftThickness: 0
        rightThickness: Appearance.padding.normal / 2
    }

    Component {
        id: taskbarContentComponent

        StyledFlickable {
            id: sidebarFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: sidebarLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: sidebarFlickable
            }

            ColumnLayout {
                id: sidebarLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Appearance.spacing.normal

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Taskbar")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true

                    StyledText {
                        text: qsTr("Status Icons")
                        font.pointSize: Appearance.font.size.normal
                    }

                    ConnectedButtonGroup {
                        rootItem: root
                        
                        options: [
                            {
                                label: qsTr("Speakers"),
                                propertyName: "showAudio",
                                onToggled: function(checked) {
                                    root.showAudio = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Microphone"),
                                propertyName: "showMicrophone",
                                onToggled: function(checked) {
                                    root.showMicrophone = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Keyboard"),
                                propertyName: "showKbLayout",
                                onToggled: function(checked) {
                                    root.showKbLayout = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Network"),
                                propertyName: "showNetwork",
                                onToggled: function(checked) {
                                    root.showNetwork = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Bluetooth"),
                                propertyName: "showBluetooth",
                                onToggled: function(checked) {
                                    root.showBluetooth = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Battery"),
                                propertyName: "showBattery",
                                onToggled: function(checked) {
                                    root.showBattery = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Capslock"),
                                propertyName: "showLockStatus",
                                onToggled: function(checked) {
                                    root.showLockStatus = checked;
                                    root.saveConfig();
                                }
                            }
                        ]
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Appearance.spacing.normal

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Workspaces")
                                font.pointSize: Appearance.font.size.normal
                            }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: workspacesShownRow.implicitHeight + Appearance.padding.large * 2
                            radius: Appearance.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

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
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

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
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

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
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

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
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

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

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Scroll Actions")
                                font.pointSize: Appearance.font.size.normal
                            }

                            ConnectedButtonGroup {
                                rootItem: root
                                
                                options: [
                                    {
                                        label: qsTr("Workspaces"),
                                        propertyName: "scrollWorkspaces",
                                        onToggled: function(checked) {
                                            root.scrollWorkspaces = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Volume"),
                                        propertyName: "scrollVolume",
                                        onToggled: function(checked) {
                                            root.scrollVolume = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Brightness"),
                                        propertyName: "scrollBrightness",
                                        onToggled: function(checked) {
                                            root.scrollBrightness = checked;
                                            root.saveConfig();
                                        }
                                    }
                                ]
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Appearance.spacing.normal

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Clock")
                                font.pointSize: Appearance.font.size.normal
                            }

                            SwitchRow {
                                label: qsTr("Show clock icon")
                                checked: root.clockShowIcon
                                onToggled: checked => {
                                    root.clockShowIcon = checked;
                                    root.saveConfig();
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Bar Behavior")
                                font.pointSize: Appearance.font.size.normal
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

                            SectionContainer {
                                contentSpacing: Appearance.spacing.normal

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.small

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.spacing.normal

                                        StyledText {
                                            text: qsTr("Drag threshold")
                                            font.pointSize: Appearance.font.size.normal
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        StyledRect {
                                            Layout.preferredWidth: 70
                                            implicitHeight: dragThresholdInput.implicitHeight + Appearance.padding.small * 2
                                            color: dragThresholdInputHover.containsMouse || dragThresholdInput.activeFocus 
                                                   ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                                   : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                            radius: Appearance.rounding.small
                                            border.width: 1
                                            border.color: dragThresholdInput.activeFocus 
                                                          ? Colours.palette.m3primary
                                                          : Qt.alpha(Colours.palette.m3outline, 0.3)

                                            Behavior on color { CAnim {} }
                                            Behavior on border.color { CAnim {} }

                                            MouseArea {
                                                id: dragThresholdInputHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.IBeamCursor
                                                acceptedButtons: Qt.NoButton
                                            }

                                            StyledTextField {
                                                id: dragThresholdInput
                                                anchors.centerIn: parent
                                                width: parent.width - Appearance.padding.normal
                                                horizontalAlignment: TextInput.AlignHCenter
                                                validator: IntValidator { bottom: 0; top: 100 }
                                                
                                                Component.onCompleted: {
                                                    text = root.dragThreshold.toString();
                                                }
                                                
                                                onTextChanged: {
                                                    if (activeFocus) {
                                                        const val = parseInt(text);
                                                        if (!isNaN(val) && val >= 0 && val <= 100) {
                                                            root.dragThreshold = val;
                                                            root.saveConfig();
                                                        }
                                                    }
                                                }
                                                onEditingFinished: {
                                                    const val = parseInt(text);
                                                    if (isNaN(val) || val < 0 || val > 100) {
                                                        text = root.dragThreshold.toString();
                                                    }
                                                }
                                            }
                                        }

                                        StyledText {
                                            text: "px"
                                            color: Colours.palette.m3outline
                                            font.pointSize: Appearance.font.size.normal
                                        }
                                    }

                                    StyledSlider {
                                        id: dragThresholdSlider

                                        Layout.fillWidth: true
                                        implicitHeight: Appearance.padding.normal * 3

                                        from: 0
                                        to: 100
                                        value: root.dragThreshold
                                        onMoved: {
                                            root.dragThreshold = Math.round(dragThresholdSlider.value);
                                            if (!dragThresholdInput.activeFocus) {
                                                dragThresholdInput.text = Math.round(dragThresholdSlider.value).toString();
                                            }
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Appearance.spacing.normal

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Popouts")
                                font.pointSize: Appearance.font.size.normal
                            }

                            SwitchRow {
                                label: qsTr("Active window")
                                checked: root.popoutActiveWindow
                                onToggled: checked => {
                                    root.popoutActiveWindow = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Tray")
                                checked: root.popoutTray
                                onToggled: checked => {
                                    root.popoutTray = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Status icons")
                                checked: root.popoutStatusIcons
                                onToggled: checked => {
                                    root.popoutStatusIcons = checked;
                                    root.saveConfig();
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Tray Settings")
                                font.pointSize: Appearance.font.size.normal
                            }

                            ConnectedButtonGroup {
                                rootItem: root
                                
                                options: [
                                    {
                                        label: qsTr("Background"),
                                        propertyName: "trayBackground",
                                        onToggled: function(checked) {
                                            root.trayBackground = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Compact"),
                                        propertyName: "trayCompact",
                                        onToggled: function(checked) {
                                            root.trayCompact = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Recolour"),
                                        propertyName: "trayRecolour",
                                        onToggled: function(checked) {
                                            root.trayRecolour = checked;
                                            root.saveConfig();
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }

            }
        }
    }
}
