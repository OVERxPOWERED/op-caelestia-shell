pragma ComponentBehavior: Bound

import ".."
import "../../launcher/services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.components.images
import qs.services
import qs.config
import qs.utils
import Caelestia.Models
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    // Appearance settings
    property real animDurationsScale: 1
    property string fontFamilyMaterial: "Material Symbols Rounded"
    property string fontFamilyMono: "CaskaydiaCove NF"
    property string fontFamilySans: "Rubik"
    property real fontSizeScale: 1
    property real paddingScale: 1
    property real roundingScale: 1
    property real spacingScale: 1
    property bool transparencyEnabled: false
    property real transparencyBase: 0.85
    property real transparencyLayers: 0.4

    // Background settings
    property bool desktopClockEnabled: true
    property bool backgroundEnabled: true
    property bool visualiserEnabled: true
    property bool visualiserAutoHide: true
    property real visualiserRounding: 1
    property real visualiserSpacing: 1

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

        onSaveFailed: err => {
            console.error("Failed to save config file:", err);
        }
    }

    function updateFromConfig(config) {
        // Update appearance settings
        if (config.appearance) {
            if (config.appearance.anim && config.appearance.anim.durations) {
                root.animDurationsScale = config.appearance.anim.durations.scale ?? 1;
            }
            if (config.appearance.font) {
                if (config.appearance.font.family) {
                    root.fontFamilyMaterial = config.appearance.font.family.material ?? "Material Symbols Rounded";
                    root.fontFamilyMono = config.appearance.font.family.mono ?? "CaskaydiaCove NF";
                    root.fontFamilySans = config.appearance.font.family.sans ?? "Rubik";
                }
                if (config.appearance.font.size) {
                    root.fontSizeScale = config.appearance.font.size.scale ?? 1;
                }
            }
            if (config.appearance.padding) {
                root.paddingScale = config.appearance.padding.scale ?? 1;
            }
            if (config.appearance.rounding) {
                root.roundingScale = config.appearance.rounding.scale ?? 1;
            }
            if (config.appearance.spacing) {
                root.spacingScale = config.appearance.spacing.scale ?? 1;
            }
            if (config.appearance.transparency) {
                root.transparencyEnabled = config.appearance.transparency.enabled ?? false;
                root.transparencyBase = config.appearance.transparency.base ?? 0.85;
                root.transparencyLayers = config.appearance.transparency.layers ?? 0.4;
            }
        }

        // Update background settings
        if (config.background) {
            root.desktopClockEnabled = config.background.desktopClock?.enabled !== undefined ? config.background.desktopClock.enabled : false;
            root.backgroundEnabled = config.background.enabled !== undefined ? config.background.enabled : true;
            if (config.background.visualiser) {
                root.visualiserEnabled = config.background.visualiser.enabled !== undefined ? config.background.visualiser.enabled : false;
                root.visualiserAutoHide = config.background.visualiser.autoHide !== undefined ? config.background.visualiser.autoHide : true;
                root.visualiserRounding = config.background.visualiser.rounding !== undefined ? config.background.visualiser.rounding : 1;
                root.visualiserSpacing = config.background.visualiser.spacing !== undefined ? config.background.visualiser.spacing : 1;
            } else {
                // Set defaults if visualiser object doesn't exist (matching BackgroundConfig defaults)
                root.visualiserEnabled = false;
                root.visualiserAutoHide = true;
                root.visualiserRounding = 1;
                root.visualiserSpacing = 1;
            }
        } else {
            // Set defaults if background object doesn't exist (matching BackgroundConfig defaults)
            root.desktopClockEnabled = false;
            root.backgroundEnabled = true;
            root.visualiserEnabled = false;
            root.visualiserAutoHide = true;
            root.visualiserRounding = 1;
            root.visualiserSpacing = 1;
        }
    }

    function collapseAllSections(exceptSection) {
        if (exceptSection !== themeModeSection) themeModeSection.expanded = false;
        if (exceptSection !== colorVariantSection) colorVariantSection.expanded = false;
        if (exceptSection !== colorSchemeSection) colorSchemeSection.expanded = false;
        if (exceptSection !== animationsSection) animationsSection.expanded = false;
        if (exceptSection !== fontsSection) fontsSection.expanded = false;
        if (exceptSection !== scalesSection) scalesSection.expanded = false;
        if (exceptSection !== transparencySection) transparencySection.expanded = false;
        if (exceptSection !== backgroundSection) backgroundSection.expanded = false;
    }

    function saveConfig() {
        if (!configFile.loaded) {
            console.error("Config file not loaded yet");
            return;
        }

        try {
            const config = JSON.parse(configFile.text());

            // Ensure appearance object exists
            if (!config.appearance) config.appearance = {};

            // Update animations
            if (!config.appearance.anim) config.appearance.anim = {};
            if (!config.appearance.anim.durations) config.appearance.anim.durations = {};
            config.appearance.anim.durations.scale = root.animDurationsScale;

            // Update fonts
            if (!config.appearance.font) config.appearance.font = {};
            if (!config.appearance.font.family) config.appearance.font.family = {};
            config.appearance.font.family.material = root.fontFamilyMaterial;
            config.appearance.font.family.mono = root.fontFamilyMono;
            config.appearance.font.family.sans = root.fontFamilySans;
            if (!config.appearance.font.size) config.appearance.font.size = {};
            config.appearance.font.size.scale = root.fontSizeScale;

            // Update scales
            if (!config.appearance.padding) config.appearance.padding = {};
            config.appearance.padding.scale = root.paddingScale;
            if (!config.appearance.rounding) config.appearance.rounding = {};
            config.appearance.rounding.scale = root.roundingScale;
            if (!config.appearance.spacing) config.appearance.spacing = {};
            config.appearance.spacing.scale = root.spacingScale;

            // Update transparency
            if (!config.appearance.transparency) config.appearance.transparency = {};
            config.appearance.transparency.enabled = root.transparencyEnabled;
            config.appearance.transparency.base = root.transparencyBase;
            config.appearance.transparency.layers = root.transparencyLayers;

            // Ensure background object exists
            if (!config.background) config.background = {};

            // Update desktop clock
            if (!config.background.desktopClock) config.background.desktopClock = {};
            config.background.desktopClock.enabled = root.desktopClockEnabled;

            // Update background enabled
            config.background.enabled = root.backgroundEnabled;

            // Update visualiser
            if (!config.background.visualiser) config.background.visualiser = {};
            config.background.visualiser.enabled = root.visualiserEnabled;
            config.background.visualiser.autoHide = root.visualiserAutoHide;
            config.background.visualiser.rounding = root.visualiserRounding;
            config.background.visualiser.spacing = root.visualiserSpacing;

            // Write back to file using setText (same simple approach that worked for taskbar)
            const jsonString = JSON.stringify(config, null, 4);
            configFile.setText(jsonString);
        } catch (e) {
            console.error("Failed to save config:", e);
        }
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

            Item {
                id: themeModeSection
                Layout.fillWidth: true
                Layout.preferredHeight: themeModeSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: themeModeSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Theme mode")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: themeModeSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = themeModeSection.expanded;
                            root.collapseAllSections(themeModeSection);
                            themeModeSection.expanded = !wasExpanded;
                        }
                    }

                    StyledText {
                        visible: themeModeSection.expanded
                        text: qsTr("Light or dark theme")
                        color: Colours.palette.m3outline
                        Layout.fillWidth: true
                    }
                }
            }

            StyledRect {
                visible: themeModeSection.expanded
                Layout.fillWidth: true
                implicitHeight: themeModeSection.expanded ? modeToggle.implicitHeight + Appearance.padding.large * 2 : 0

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: modeToggle

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Dark mode")
                    }

                    StyledSwitch {
                        checked: !Colours.currentLight
                        onToggled: {
                            Colours.setMode(checked ? "dark" : "light");
                        }
                    }
                }
            }

            Item {
                id: colorVariantSection
                Layout.fillWidth: true
                Layout.preferredHeight: colorVariantSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: colorVariantSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Color variant")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: colorVariantSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = colorVariantSection.expanded;
                            root.collapseAllSections(colorVariantSection);
                            colorVariantSection.expanded = !wasExpanded;
                        }
                    }

                    StyledText {
                        visible: colorVariantSection.expanded
                        text: qsTr("Material theme variant")
                        color: Colours.palette.m3outline
                        Layout.fillWidth: true
                    }
                }
            }

            StyledListView {
                visible: colorVariantSection.expanded
                Layout.fillWidth: true
                implicitHeight: colorVariantSection.expanded ? Math.min(400, M3Variants.list.length * 60) : 0
                Layout.topMargin: 0

                Behavior on implicitHeight {
                    Anim {}
                }

                model: M3Variants.list
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property var modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            const variant = modelData.variant;
                            
                            // Optimistic update - set immediately
                            Schemes.currentVariant = variant;
                            
                            // Execute the command
                            Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);
                            
                            // Reload after a delay to confirm
                            Qt.callLater(() => {
                                reloadTimer.restart();
                            });
                        }
                    }
                    
                    Timer {
                        id: reloadTimer
                        interval: 300
                        onTriggered: {
                            Schemes.reload();
                        }
                    }

                    RowLayout {
                        id: variantRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: modelData.icon
                            font.pointSize: Appearance.font.size.large
                            fill: modelData.variant === Schemes.currentVariant ? 1 : 0
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.weight: modelData.variant === Schemes.currentVariant ? 500 : 400
                        }

                        MaterialIcon {
                            visible: modelData.variant === Schemes.currentVariant
                            text: "check"
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.large
                        }
                    }

                    implicitHeight: variantRow.implicitHeight + Appearance.padding.normal * 2
                }
            }

            Item {
                id: colorSchemeSection
                Layout.fillWidth: true
                Layout.preferredHeight: colorSchemeSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: colorSchemeSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Color scheme")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: colorSchemeSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = colorSchemeSection.expanded;
                            root.collapseAllSections(colorSchemeSection);
                            colorSchemeSection.expanded = !wasExpanded;
                        }
                    }

                    StyledText {
                        visible: colorSchemeSection.expanded
                        text: qsTr("Available color schemes")
                        color: Colours.palette.m3outline
                        Layout.fillWidth: true
                    }
                }
            }

            StyledListView {
                visible: colorSchemeSection.expanded
                Layout.fillWidth: true
                implicitHeight: colorSchemeSection.expanded ? Math.min(400, Schemes.list.length * 80) : 0
                Layout.topMargin: 0

                Behavior on implicitHeight {
                    Anim {}
                }

                model: Schemes.list
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property var modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    readonly property string schemeKey: `${modelData.name} ${modelData.flavour}`
                    readonly property bool isCurrent: schemeKey === Schemes.currentScheme

                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            const name = modelData.name;
                            const flavour = modelData.flavour;
                            const schemeKey = `${name} ${flavour}`;
                            
                            // Optimistic update - set immediately
                            Schemes.currentScheme = schemeKey;
                            
                            // Execute the command
                            Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name, "-f", flavour]);
                            
                            // Reload after a delay to confirm
                            Qt.callLater(() => {
                                reloadTimer.restart();
                            });
                        }
                    }
                    
                    Timer {
                        id: reloadTimer
                        interval: 300
                        onTriggered: {
                            Schemes.reload();
                        }
                    }

                    RowLayout {
                        id: schemeRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledRect {
                            id: preview

                            anchors.verticalCenter: parent.verticalCenter

                            border.width: 1
                            border.color: Qt.alpha(`#${modelData.colours?.outline}`, 0.5)

                            color: `#${modelData.colours?.surface}`
                            radius: Appearance.rounding.full
                            implicitWidth: iconPlaceholder.implicitWidth
                            implicitHeight: iconPlaceholder.implicitWidth

                            MaterialIcon {
                                id: iconPlaceholder
                                visible: false
                                text: "circle"
                                font.pointSize: Appearance.font.size.large
                            }

                            Item {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right

                                implicitWidth: parent.implicitWidth / 2
                                clip: true

                                StyledRect {
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right

                                    implicitWidth: preview.implicitWidth
                                    color: `#${modelData.colours?.primary}`
                                    radius: Appearance.rounding.full
                                }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: modelData.flavour ?? ""
                                font.pointSize: Appearance.font.size.normal
                            }

                            StyledText {
                                text: modelData.name ?? ""
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline

                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.right: parent.right
                            }
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: schemeRow.implicitHeight + Appearance.padding.normal * 2
                }
            }

            Item {
                id: animationsSection
                Layout.fillWidth: true
                Layout.preferredHeight: animationsSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: animationsSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Animations")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: animationsSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = animationsSection.expanded;
                            root.collapseAllSections(animationsSection);
                            animationsSection.expanded = !wasExpanded;
                        }
                    }
                }
            }

            StyledRect {
                visible: animationsSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: animationsSection.expanded ? animDurationsScaleRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: animDurationsScaleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Animation duration scale")
                    }

                    CustomSpinBox {
                        id: animDurationsScaleSpinBox
                        min: 0.1
                        max: 5
                        value: root.animDurationsScale
                        onValueModified: value => {
                            root.animDurationsScale = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            Item {
                id: fontsSection
                Layout.fillWidth: true
                Layout.preferredHeight: fontsSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: fontsSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Fonts")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: fontsSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = fontsSection.expanded;
                            root.collapseAllSections(fontsSection);
                            fontsSection.expanded = !wasExpanded;
                        }
                    }
                }
            }

            StyledText {
                visible: fontsSection.expanded
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Material font family")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledListView {
                visible: fontsSection.expanded
                Layout.fillWidth: true
                implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0
                Layout.topMargin: 0

                Behavior on implicitHeight {
                    Anim {}
                }

                model: Qt.fontFamilies()
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property string modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    readonly property bool isCurrent: modelData === root.fontFamilyMaterial
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            root.fontFamilyMaterial = modelData;
                            root.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilyMaterialRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilyMaterialRow.implicitHeight + Appearance.padding.normal * 2
                }
            }

            StyledText {
                visible: fontsSection.expanded
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Monospace font family")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledListView {
                visible: fontsSection.expanded
                Layout.fillWidth: true
                implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0
                Layout.topMargin: 0

                Behavior on implicitHeight {
                    Anim {}
                }

                model: Qt.fontFamilies()
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property string modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    readonly property bool isCurrent: modelData === root.fontFamilyMono
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            root.fontFamilyMono = modelData;
                            root.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilyMonoRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilyMonoRow.implicitHeight + Appearance.padding.normal * 2
                }
            }

            StyledText {
                visible: fontsSection.expanded
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Sans-serif font family")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledListView {
                visible: fontsSection.expanded
                Layout.fillWidth: true
                implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0
                Layout.topMargin: 0

                Behavior on implicitHeight {
                    Anim {}
                }

                model: Qt.fontFamilies()
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property string modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    readonly property bool isCurrent: modelData === root.fontFamilySans
                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: isCurrent ? 1 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        function onClicked(): void {
                            root.fontFamilySans = modelData;
                            root.saveConfig();
                        }
                    }

                    RowLayout {
                        id: fontFamilySansRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: modelData
                            font.pointSize: Appearance.font.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            active: isCurrent
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.large
                            }
                        }
                    }

                    implicitHeight: fontFamilySansRow.implicitHeight + Appearance.padding.normal * 2
                }
            }

            StyledRect {
                visible: fontsSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: fontsSection.expanded ? fontSizeScaleRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: fontSizeScaleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Font size scale")
                    }

                    CustomSpinBox {
                        id: fontSizeScaleSpinBox
                        min: 0.1
                        max: 5
                        value: root.fontSizeScale
                        onValueModified: value => {
                            root.fontSizeScale = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            Item {
                id: scalesSection
                Layout.fillWidth: true
                Layout.preferredHeight: scalesSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: scalesSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Scales")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: scalesSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = scalesSection.expanded;
                            root.collapseAllSections(scalesSection);
                            scalesSection.expanded = !wasExpanded;
                        }
                    }
                }
            }

            StyledRect {
                visible: scalesSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: scalesSection.expanded ? paddingScaleRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: paddingScaleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Padding scale")
                    }

                    CustomSpinBox {
                        id: paddingScaleSpinBox
                        min: 0.1
                        max: 5
                        value: root.paddingScale
                        onValueModified: value => {
                            root.paddingScale = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: scalesSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: scalesSection.expanded ? roundingScaleRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: roundingScaleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Rounding scale")
                    }

                    CustomSpinBox {
                        id: roundingScaleSpinBox
                        min: 0.1
                        max: 5
                        value: root.roundingScale
                        onValueModified: value => {
                            root.roundingScale = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: scalesSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: scalesSection.expanded ? spacingScaleRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: spacingScaleRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Spacing scale")
                    }

                    CustomSpinBox {
                        id: spacingScaleSpinBox
                        min: 0.1
                        max: 5
                        value: root.spacingScale
                        onValueModified: value => {
                            root.spacingScale = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            Item {
                id: transparencySection
                Layout.fillWidth: true
                Layout.preferredHeight: transparencySectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: transparencySectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Transparency")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: transparencySection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = transparencySection.expanded;
                            root.collapseAllSections(transparencySection);
                            transparencySection.expanded = !wasExpanded;
                        }
                    }
                }
            }

            StyledRect {
                visible: transparencySection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: transparencySection.expanded ? transparencyEnabledRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: transparencyEnabledRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Transparency enabled")
                    }

                    StyledSwitch {
                        id: transparencyEnabledSwitch
                        checked: root.transparencyEnabled
                        onToggled: {
                            root.transparencyEnabled = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: transparencySection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: transparencySection.expanded ? transparencyBaseRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: transparencyBaseRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Transparency base")
                    }

                    CustomSpinBox {
                        id: transparencyBaseSpinBox
                        min: 0
                        max: 1
                        value: root.transparencyBase
                        onValueModified: value => {
                            root.transparencyBase = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: transparencySection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: transparencySection.expanded ? transparencyLayersRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: transparencyLayersRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Transparency layers")
                    }

                    CustomSpinBox {
                        id: transparencyLayersSpinBox
                        min: 0
                        max: 1
                        value: root.transparencyLayers
                        onValueModified: value => {
                            root.transparencyLayers = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            Item {
                id: backgroundSection
                Layout.fillWidth: true
                Layout.preferredHeight: backgroundSectionHeader.implicitHeight
                property bool expanded: false

                ColumnLayout {
                    id: backgroundSectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.topMargin: Appearance.spacing.large
                            text: qsTr("Background")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: "expand_more"
                            rotation: backgroundSection.expanded ? 180 : 0
                            color: Colours.palette.m3onSurface
                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Appearance.padding.normal
                        anchors.rightMargin: -Appearance.padding.normal
                        function onClicked(): void {
                            const wasExpanded = backgroundSection.expanded;
                            root.collapseAllSections(backgroundSection);
                            backgroundSection.expanded = !wasExpanded;
                        }
                    }
                }
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? desktopClockRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: desktopClockRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Desktop clock")
                    }

                    StyledSwitch {
                        id: desktopClockSwitch
                        checked: root.desktopClockEnabled
                        onToggled: {
                            root.desktopClockEnabled = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? backgroundEnabledRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: backgroundEnabledRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Background enabled")
                    }

                    StyledSwitch {
                        id: backgroundEnabledSwitch
                        checked: root.backgroundEnabled
                        onToggled: {
                            root.backgroundEnabled = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledText {
                visible: backgroundSection.expanded
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Visualiser")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? visualiserEnabledRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: visualiserEnabledRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Visualiser enabled")
                    }

                    StyledSwitch {
                        id: visualiserEnabledSwitch
                        checked: root.visualiserEnabled
                        onToggled: {
                            root.visualiserEnabled = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? visualiserAutoHideRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: visualiserAutoHideRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Visualiser auto hide")
                    }

                    StyledSwitch {
                        id: visualiserAutoHideSwitch
                        checked: root.visualiserAutoHide
                        onToggled: {
                            root.visualiserAutoHide = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? visualiserRoundingRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: visualiserRoundingRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Visualiser rounding")
                    }

                    CustomSpinBox {
                        id: visualiserRoundingSpinBox
                        min: 0
                        max: 10
                        value: Math.round(root.visualiserRounding)
                        onValueModified: value => {
                            root.visualiserRounding = value;
                            root.saveConfig();
                        }
                    }
                }
            }

            StyledRect {
                visible: backgroundSection.expanded
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: backgroundSection.expanded ? visualiserSpacingRow.implicitHeight + Appearance.padding.large * 2 : 0
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: visualiserSpacingRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Visualiser spacing")
                    }

                    CustomSpinBox {
                        id: visualiserSpacingSpinBox
                        min: 0
                        max: 10
                        value: Math.round(root.visualiserSpacing)
                        onValueModified: value => {
                            root.visualiserSpacing = value;
                            root.saveConfig();
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
                text: "palette"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Appearance settings")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Theme mode")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Colours.currentLight ? qsTr("Light mode") : qsTr("Dark mode")
                color: Colours.palette.m3outline
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Wallpaper")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Select a wallpaper")
                color: Colours.palette.m3outline
            }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.alignment: Qt.AlignHCenter

                    columns: Math.max(1, Math.floor(parent.width / 200))
                    rowSpacing: Appearance.spacing.normal
                    columnSpacing: Appearance.spacing.normal
                    
                    // Center the grid content
                    Layout.maximumWidth: {
                        const cols = columns;
                        const itemWidth = 180;
                        const spacing = columnSpacing;
                        return cols * itemWidth + (cols - 1) * spacing;
                    }

                    Repeater {
                        model: Wallpapers.list

                        delegate: Item {
                            required property var modelData

                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 120
                            Layout.minimumWidth: 180
                            Layout.minimumHeight: 120

                            readonly property bool isCurrent: modelData.path === Wallpapers.actualCurrent
                            readonly property real imageWidth: Math.max(1, width)
                            readonly property real imageHeight: Math.max(1, height)

                            StateLayer {
                                radius: Appearance.rounding.normal

                                function onClicked(): void {
                                    Wallpapers.setWallpaper(modelData.path);
                                }
                            }

                            StyledClippingRect {
                                id: image

                                anchors.fill: parent
                                color: Colours.tPalette.m3surfaceContainer
                                radius: Appearance.rounding.normal

                                border.width: isCurrent ? 2 : 0
                                border.color: Colours.palette.m3primary

                                CachingImage {
                                    id: cachingImage

                                    path: modelData.path
                                    anchors.fill: parent
                                    
                                    // Ensure sourceSize is always set to valid dimensions
                                    sourceSize: Qt.size(
                                        Math.max(1, Math.floor(parent.width)),
                                        Math.max(1, Math.floor(parent.height))
                                    )
                                    
                                    // Show when ready, hide if fallback is showing
                                    opacity: status === Image.Ready && !fallbackImage.visible ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                // Fallback: Direct image load if caching fails or is slow
                                Image {
                                    id: fallbackImage

                                    anchors.fill: parent
                                    source: modelData.path
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(
                                        Math.max(1, Math.floor(parent.width)),
                                        Math.max(1, Math.floor(parent.height))
                                    )
                                    
                                    // Show if caching image hasn't loaded after a delay
                                    visible: opacity > 0
                                    opacity: 0
                                    
                                    Timer {
                                        id: fallbackTimer
                                        interval: 500
                                        running: cachingImage.status === Image.Loading || (cachingImage.status !== Image.Ready && cachingImage.status !== Image.Null)
                                        onTriggered: {
                                            if (cachingImage.status !== Image.Ready && fallbackImage.status === Image.Ready) {
                                                fallbackImage.opacity = 1;
                                            }
                                        }
                                    }
                                    
                                    // Also check status changes
                                    onStatusChanged: {
                                        if (status === Image.Ready && cachingImage.status !== Image.Ready) {
                                            Qt.callLater(() => {
                                                if (cachingImage.status !== Image.Ready) {
                                                    fallbackImage.opacity = 1;
                                                }
                                            });
                                        }
                                    }
                                    
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                MaterialIcon {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Appearance.padding.small

                                    visible: isCurrent
                                    text: "check_circle"
                                    color: Colours.palette.m3primary
                                    font.pointSize: Appearance.font.size.large
                                }
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: Appearance.padding.small

                                text: modelData.relativePath
                                font.pointSize: Appearance.font.size.small
                                color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                elide: Text.ElideRight
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


