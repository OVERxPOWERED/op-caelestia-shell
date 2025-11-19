pragma ComponentBehavior: Bound

import ".."
import "../components"
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
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../../utils/scripts/fuzzysort.js" as Fuzzy

Item {
    id: root

    required property Session session

    property var selectedApp: root.session.launcher.active
    property bool hideFromLauncherChecked: false

    anchors.fill: parent

    onSelectedAppChanged: {
        root.session.launcher.active = root.selectedApp;
        updateToggleState();
    }

    Connections {
        target: root.session.launcher
        function onActiveChanged() {
            root.selectedApp = root.session.launcher.active;
            updateToggleState();
        }
    }

    function updateToggleState() {
        if (!root.selectedApp) {
            root.hideFromLauncherChecked = false;
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        if (Config.launcher.hiddenApps && Config.launcher.hiddenApps.length > 0) {
            root.hideFromLauncherChecked = Config.launcher.hiddenApps.includes(appId);
        } else {
            root.hideFromLauncherChecked = false;
        }
    }

    function saveHiddenApps(isHidden) {
        if (!root.selectedApp) {
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        // Create a new array to ensure change detection
        const hiddenApps = Config.launcher.hiddenApps ? [...Config.launcher.hiddenApps] : [];

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

        // Update Config
        Config.launcher.hiddenApps = hiddenApps;

        // Persist changes to disk
        Config.save();
    }


    AppDb {
        id: allAppsDb

        path: `${Paths.state}/apps.sqlite`
        entries: DesktopEntries.applications.values  // No filter - show all apps
    }

    property string searchText: ""

    function filterApps(search: string): list<var> {
        // If search is empty, return all apps directly
        if (!search || search.trim() === "") {
            // Convert QQmlListProperty to array
            const apps = [];
            for (let i = 0; i < allAppsDb.apps.length; i++) {
                apps.push(allAppsDb.apps[i]);
            }
            return apps;
        }

        if (!allAppsDb.apps || allAppsDb.apps.length === 0) {
            return [];
        }

        // Prepare apps for fuzzy search
        const preparedApps = [];
        for (let i = 0; i < allAppsDb.apps.length; i++) {
            const app = allAppsDb.apps[i];
            const name = app.name || app.entry?.name || "";
            preparedApps.push({
                _item: app,
                name: Fuzzy.prepare(name)
            });
        }

        // Perform fuzzy search
        const results = Fuzzy.go(search, preparedApps, {
            all: true,
            keys: ["name"],
            scoreFn: r => r[0].score
        });

        // Return sorted by score (highest first)
        return results
            .sort((a, b) => b._score - a._score)
            .map(r => r.obj._item);
    }

    property list<var> filteredApps: []

    function updateFilteredApps() {
        filteredApps = filterApps(searchText);
    }

    onSearchTextChanged: {
        updateFilteredApps();
    }

    Component.onCompleted: {
        updateFilteredApps();
    }

    Connections {
        target: allAppsDb
        function onAppsChanged() {
            updateFilteredApps();
        }
    }

    SplitPaneLayout {
        anchors.fill: parent

        leftContent: Component {

            ColumnLayout {
                id: leftLauncherLayout
                anchors.fill: parent

                spacing: Appearance.spacing.small

                RowLayout {
                spacing: Appearance.spacing.smaller

                StyledText {
                    text: qsTr("Launcher")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
                }

                ToggleButton {
                    toggled: !root.session.launcher.active
                    icon: "settings"
                    accent: "Primary"

                    onClicked: {
                        if (root.session.launcher.active) {
                            root.session.launcher.active = null;
                        } else {
                            // Toggle to show settings - if there are apps, select the first one, otherwise show settings
                            if (root.filteredApps.length > 0) {
                                root.session.launcher.active = root.filteredApps[0];
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Applications (%1)").arg(root.searchText ? root.filteredApps.length : allAppsDb.apps.length)
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
            }

            StyledText {
                text: qsTr("All applications available in the launcher")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                Layout.bottomMargin: Appearance.spacing.small

                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                radius: Appearance.rounding.full

                implicitHeight: Math.max(searchIcon.implicitHeight, searchField.implicitHeight, clearIcon.implicitHeight)

                MaterialIcon {
                    id: searchIcon

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.normal

                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledTextField {
                    id: searchField

                    anchors.left: searchIcon.right
                    anchors.right: clearIcon.left
                    anchors.leftMargin: Appearance.spacing.small
                    anchors.rightMargin: Appearance.spacing.small

                    topPadding: Appearance.padding.normal
                    bottomPadding: Appearance.padding.normal

                    placeholderText: qsTr("Search applications...")

                    onTextChanged: {
                        root.searchText = text;
                    }
                }

                MaterialIcon {
                    id: clearIcon

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.padding.normal

                    width: searchField.text ? implicitWidth : implicitWidth / 2
                    opacity: {
                        if (!searchField.text)
                            return 0;
                        if (clearMouse.pressed)
                            return 0.7;
                        if (clearMouse.containsMouse)
                            return 0.8;
                        return 1;
                    }

                    text: "close"
                    color: Colours.palette.m3onSurfaceVariant

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: searchField.text ? Qt.PointingHandCursor : undefined

                        onClicked: searchField.text = ""
                    }

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }
            }

            Loader {
                id: appsListLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                asynchronous: true
                active: {
                    // Lazy load: activate when left pane is loaded
                    // The ListView will load asynchronously, and search will work because filteredApps
                    // is updated regardless of whether the ListView is loaded
                    // Access loader through parent - this will be set when component loads
                    return true;
                }

                sourceComponent: StyledListView {
                    id: appsListView
                    
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: root.filteredApps
                    spacing: Appearance.spacing.small / 2
                    clip: true

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: parent
                    }

                    delegate: StyledRect {
                        required property var modelData

                        width: parent ? parent.width : 0

                        readonly property bool isSelected: root.selectedApp === modelData

                        color: isSelected ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"
                        radius: Appearance.rounding.normal

                        opacity: 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }
                        }

                        Component.onCompleted: {
                            opacity = 1;
                        }

                        StateLayer {
                            function onClicked(): void {
                                root.session.launcher.active = modelData;
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
        }
        }

        rightContent: Component {
            Item {
                id: rightLauncherPane

                property var pane: root.session.launcher.active
                property string paneId: pane ? (pane.id || pane.entry?.id || "") : ""
                property Component targetComponent: settings
                property Component nextComponent: settings
                property var displayedApp: null

                function getComponentForPane() {
                    return pane ? appDetails : settings;
                }

                Component.onCompleted: {
                    displayedApp = pane;
                    targetComponent = getComponentForPane();
                    nextComponent = targetComponent;
                }

                Loader {
                    id: rightLauncherLoader

                    anchors.fill: parent

                    opacity: 1
                    scale: 1
                    transformOrigin: Item.Center
                    clip: false

                    asynchronous: true
                    sourceComponent: rightLauncherPane.targetComponent
                    active: true

                    // Expose displayedApp to loaded components
                    property var displayedApp: rightLauncherPane.displayedApp

                    onItemChanged: {
                        // Ensure displayedApp is set when item is created (for async loading)
                        if (item && rightLauncherPane.pane && rightLauncherPane.displayedApp !== rightLauncherPane.pane) {
                            rightLauncherPane.displayedApp = rightLauncherPane.pane;
                        }
                    }
                }

                Behavior on paneId {
                    PaneTransition {
                        target: rightLauncherLoader
                        propertyActions: [
                            PropertyAction {
                                target: rightLauncherPane
                                property: "displayedApp"
                                value: rightLauncherPane.pane
                            },
                            PropertyAction {
                                target: rightLauncherLoader
                                property: "active"
                                value: false
                            },
                            PropertyAction {
                                target: rightLauncherPane
                                property: "targetComponent"
                                value: rightLauncherPane.nextComponent
                            },
                            PropertyAction {
                                target: rightLauncherLoader
                                property: "active"
                                value: true
                            }
                        ]
                    }
                }

                onPaneChanged: {
                    nextComponent = getComponentForPane();
                    paneId = pane ? (pane.id || pane.entry?.id || "") : "";
                }

                onDisplayedAppChanged: {
                    if (displayedApp) {
                        const appId = displayedApp.id || displayedApp.entry?.id;
                        if (Config.launcher.hiddenApps && Config.launcher.hiddenApps.length > 0) {
                            root.hideFromLauncherChecked = Config.launcher.hiddenApps.includes(appId);
                        } else {
                            root.hideFromLauncherChecked = false;
                        }
                    } else {
                        root.hideFromLauncherChecked = false;
                    }
                }
            }
        }
    }

    Component {
        id: settings

        StyledFlickable {
            id: settingsFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: settingsFlickable
            }

            Settings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    Component {
        id: appDetails

        ColumnLayout {
            id: appDetailsLayout
            anchors.fill: parent

            // Get displayedApp from parent Loader (the Loader has displayedApp property we set)
            readonly property var displayedApp: parent && parent.displayedApp !== undefined ? parent.displayedApp : null

            spacing: Appearance.spacing.normal

            Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: Appearance.padding.large * 2
            Layout.rightMargin: Appearance.padding.large * 2
            Layout.topMargin: Appearance.padding.large * 2
            implicitWidth: iconLoader.implicitWidth
            implicitHeight: iconLoader.implicitHeight

            Loader {
                id: iconLoader
                sourceComponent: parent.parent.displayedApp ? appIconComponent : defaultIconComponent
            }

            Component {
                id: appIconComponent
                IconImage {
                    implicitSize: Appearance.font.size.extraLarge * 3 * 2
                    source: {
                        const app = iconLoader.parent.parent.displayedApp;
                        if (!app) return "image-missing";
                        const entry = app.entry;
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
            Layout.leftMargin: Appearance.padding.large * 2
            Layout.rightMargin: Appearance.padding.large * 2
            text: displayedApp ? (displayedApp.name || displayedApp.entry?.name || qsTr("Application Details")) : qsTr("Launcher Applications")
            font.pointSize: Appearance.font.size.large
            font.bold: true
        }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Appearance.spacing.large
                Layout.leftMargin: Appearance.padding.large * 2
                Layout.rightMargin: Appearance.padding.large * 2

                StyledFlickable {
                    id: detailsFlickable
                    anchors.fill: parent
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: debugLayout.height

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: parent
                    }

                    ColumnLayout {
                        id: debugLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Appearance.spacing.normal

                    SwitchRow {
                        Layout.topMargin: Appearance.spacing.normal
                        visible: appDetailsLayout.displayedApp !== null
                        label: qsTr("Hide from launcher")
                        checked: root.hideFromLauncherChecked
                        enabled: appDetailsLayout.displayedApp !== null
                        onToggled: checked => {
                            root.hideFromLauncherChecked = checked;
                            const app = appDetailsLayout.displayedApp;
                            if (app) {
                                const appId = app.id || app.entry?.id;
                                const hiddenApps = Config.launcher.hiddenApps ? [...Config.launcher.hiddenApps] : [];
                                if (checked) {
                                    if (!hiddenApps.includes(appId)) {
                                        hiddenApps.push(appId);
                                    }
                                } else {
                                    const index = hiddenApps.indexOf(appId);
                                    if (index !== -1) {
                                        hiddenApps.splice(index, 1);
                                    }
                                }
                                Config.launcher.hiddenApps = hiddenApps;
                                Config.save();
                            }
                        }
                    }

                    }
                }
            }
        }
    }
}
