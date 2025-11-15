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
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    // Appearance settings
    property real animDurationsScale: Config.appearance.anim.durations.scale ?? 1
    property string fontFamilyMaterial: Config.appearance.font.family.material ?? "Material Symbols Rounded"
    property string fontFamilyMono: Config.appearance.font.family.mono ?? "CaskaydiaCove NF"
    property string fontFamilySans: Config.appearance.font.family.sans ?? "Rubik"
    property real fontSizeScale: Config.appearance.font.size.scale ?? 1
    property real paddingScale: Config.appearance.padding.scale ?? 1
    property real roundingScale: Config.appearance.rounding.scale ?? 1
    property real spacingScale: Config.appearance.spacing.scale ?? 1
    property bool transparencyEnabled: Config.appearance.transparency.enabled ?? false
    property real transparencyBase: Config.appearance.transparency.base ?? 0.85
    property real transparencyLayers: Config.appearance.transparency.layers ?? 0.4
    property real borderRounding: Config.border.rounding ?? 1
    property real borderThickness: Config.border.thickness ?? 1

    // Background settings
    property bool desktopClockEnabled: Config.background.desktopClock.enabled ?? false
    property bool backgroundEnabled: Config.background.enabled ?? true
    property bool visualiserEnabled: Config.background.visualiser.enabled ?? false
    property bool visualiserAutoHide: Config.background.visualiser.autoHide ?? true
    property real visualiserRounding: Config.background.visualiser.rounding ?? 1
    property real visualiserSpacing: Config.background.visualiser.spacing ?? 1

    anchors.fill: parent

    spacing: 0

    function collapseAllSections(exceptSection) {
        if (exceptSection !== themeModeSection)
            themeModeSection.expanded = false;
        if (exceptSection !== colorVariantSection)
            colorVariantSection.expanded = false;
        if (exceptSection !== colorSchemeSection)
            colorSchemeSection.expanded = false;
        if (exceptSection !== animationsSection)
            animationsSection.expanded = false;
        if (exceptSection !== fontsSection)
            fontsSection.expanded = false;
        if (exceptSection !== scalesSection)
            scalesSection.expanded = false;
        if (exceptSection !== transparencySection)
            transparencySection.expanded = false;
        if (exceptSection !== borderSection)
            borderSection.expanded = false;
        if (exceptSection !== backgroundSection)
            backgroundSection.expanded = false;
    }

    function saveConfig() {
        // Update animations
        Config.appearance.anim.durations.scale = root.animDurationsScale;

        // Update fonts
        Config.appearance.font.family.material = root.fontFamilyMaterial;
        Config.appearance.font.family.mono = root.fontFamilyMono;
        Config.appearance.font.family.sans = root.fontFamilySans;
        Config.appearance.font.size.scale = root.fontSizeScale;

        // Update scales
        Config.appearance.padding.scale = root.paddingScale;
        Config.appearance.rounding.scale = root.roundingScale;
        Config.appearance.spacing.scale = root.spacingScale;

        // Update transparency
        Config.appearance.transparency.enabled = root.transparencyEnabled;
        Config.appearance.transparency.base = root.transparencyBase;
        Config.appearance.transparency.layers = root.transparencyLayers;

        // Update desktop clock
        Config.background.desktopClock.enabled = root.desktopClockEnabled;

        // Update background enabled
        Config.background.enabled = root.backgroundEnabled;

        // Update visualiser
        Config.background.visualiser.enabled = root.visualiserEnabled;
        Config.background.visualiser.autoHide = root.visualiserAutoHide;
        Config.background.visualiser.rounding = root.visualiserRounding;
        Config.background.visualiser.spacing = root.visualiserSpacing;

        // Update border
        Config.border.rounding = root.borderRounding;
        Config.border.thickness = root.borderThickness;
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
                    id: themeModeSection
                    title: qsTr("Theme mode")
                    description: qsTr("Light or dark theme")
                    onToggleRequested: {
                        root.collapseAllSections(themeModeSection);
                    }

                    SwitchRow {
                        label: qsTr("Dark mode")
                        checked: !Colours.currentLight
                        onToggled: checked => {
                            Colours.setMode(checked ? "dark" : "light");
                        }
                    }
                }

                CollapsibleSection {
                    id: colorVariantSection
                    title: qsTr("Color variant")
                    description: qsTr("Material theme variant")
                    onToggleRequested: {
                        root.collapseAllSections(colorVariantSection);
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        implicitHeight: colorVariantSection.expanded ? Math.min(400, M3Variants.list.length * 60) : 0

                        model: M3Variants.list
                        spacing: Appearance.spacing.small / 2
                        clip: true

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: parent
                        }

                        delegate: StyledRect {
                            required property var modelData

                            width: parent ? parent.width : 0

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
                }

                CollapsibleSection {
                    id: colorSchemeSection
                    title: qsTr("Color scheme")
                    description: qsTr("Available color schemes")
                    onToggleRequested: {
                        root.collapseAllSections(colorSchemeSection);
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        implicitHeight: colorSchemeSection.expanded ? Math.min(400, Schemes.list.length * 80) : 0

                        model: Schemes.list
                        spacing: Appearance.spacing.small / 2
                        clip: true

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: parent
                        }

                        delegate: StyledRect {
                            required property var modelData

                            width: parent ? parent.width : 0

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

                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal

                                spacing: Appearance.spacing.normal

                                StyledRect {
                                    id: preview

                                    Layout.alignment: Qt.AlignVCenter

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
                }

                CollapsibleSection {
                    id: animationsSection
                    title: qsTr("Animations")
                    onToggleRequested: {
                        root.collapseAllSections(animationsSection);
                    }

                    SpinBoxRow {
                        label: qsTr("Animation duration scale")
                        min: 0.1
                        max: 5
                        value: root.animDurationsScale
                        onValueModified: value => {
                            root.animDurationsScale = value;
                            root.saveConfig();
                        }
                    }
                }

                CollapsibleSection {
                    id: fontsSection
                    title: qsTr("Fonts")
                    onToggleRequested: {
                        root.collapseAllSections(fontsSection);
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Material font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0

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
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Monospace font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0

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
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Sans-serif font family")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    StyledListView {
                        Layout.fillWidth: true
                        implicitHeight: fontsSection.expanded ? Math.min(300, Qt.fontFamilies().length * 50) : 0

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

                    SpinBoxRow {
                        label: qsTr("Font size scale")
                        min: 0.1
                        max: 5
                        value: root.fontSizeScale
                        onValueModified: value => {
                            root.fontSizeScale = value;
                            root.saveConfig();
                        }
                    }
                }

                CollapsibleSection {
                    id: scalesSection
                    title: qsTr("Scales")
                    onToggleRequested: {
                        root.collapseAllSections(scalesSection);
                    }

                    SpinBoxRow {
                        label: qsTr("Padding scale")
                        min: 0.1
                        max: 5
                        value: root.paddingScale
                        onValueModified: value => {
                            root.paddingScale = value;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Rounding scale")
                        min: 0.1
                        max: 5
                        value: root.roundingScale
                        onValueModified: value => {
                            root.roundingScale = value;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Spacing scale")
                        min: 0.1
                        max: 5
                        value: root.spacingScale
                        onValueModified: value => {
                            root.spacingScale = value;
                            root.saveConfig();
                        }
                    }
                }

                CollapsibleSection {
                    id: transparencySection
                    title: qsTr("Transparency")
                    onToggleRequested: {
                        root.collapseAllSections(transparencySection);
                    }

                    SwitchRow {
                        label: qsTr("Transparency enabled")
                        checked: root.transparencyEnabled
                        onToggled: checked => {
                            root.transparencyEnabled = checked;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Transparency base")
                        min: 0
                        max: 1
                        value: root.transparencyBase
                        onValueModified: value => {
                            root.transparencyBase = value;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Transparency layers")
                        min: 0
                        max: 1
                        value: root.transparencyLayers
                        onValueModified: value => {
                            root.transparencyLayers = value;
                            root.saveConfig();
                        }
                    }
                }

                CollapsibleSection {
                    id: borderSection
                    title: qsTr("Border")
                    onToggleRequested: {
                        root.collapseAllSections(borderSection);
                    }

                    SpinBoxRow {
                        label: qsTr("Border rounding")
                        min: 0.1
                        max: 5
                        value: root.borderRounding
                        onValueModified: value => {
                            root.borderRounding = value;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Border thickness")
                        min: 0.1
                        max: 5
                        value: root.borderThickness
                        onValueModified: value => {
                            root.borderThickness = value;
                            root.saveConfig();
                        }
                    }
                }

                CollapsibleSection {
                    id: backgroundSection
                    title: qsTr("Background")
                    onToggleRequested: {
                        root.collapseAllSections(backgroundSection);
                    }

                    SwitchRow {
                        label: qsTr("Desktop clock")
                        checked: root.desktopClockEnabled
                        onToggled: checked => {
                            root.desktopClockEnabled = checked;
                            root.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Background enabled")
                        checked: root.backgroundEnabled
                        onToggled: checked => {
                            root.backgroundEnabled = checked;
                            root.saveConfig();
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Visualiser")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 500
                    }

                    SwitchRow {
                        label: qsTr("Visualiser enabled")
                        checked: root.visualiserEnabled
                        onToggled: checked => {
                            root.visualiserEnabled = checked;
                            root.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Visualiser auto hide")
                        checked: root.visualiserAutoHide
                        onToggled: checked => {
                            root.visualiserAutoHide = checked;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Visualiser rounding")
                        min: 0
                        max: 10
                        value: Math.round(root.visualiserRounding)
                        onValueModified: value => {
                            root.visualiserRounding = value;
                            root.saveConfig();
                        }
                    }

                    SpinBoxRow {
                        label: qsTr("Visualiser spacing")
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
                    text: "palette"
                    font.pointSize: Appearance.font.size.extraLarge * 3
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Appearance Settings")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Wallpaper")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 600
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Select a wallpaper")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter

                    columns: Math.max(2, Math.floor(parent.width / 200))
                    rowSpacing: Appearance.spacing.normal
                    columnSpacing: Appearance.spacing.normal

                    // Center the grid content
                    Layout.maximumWidth: {
                        const cols = columns;
                        const itemWidth = 200;
                        const spacing = columnSpacing;
                        return cols * itemWidth + (cols - 1) * spacing;
                    }

                    Repeater {
                        model: Wallpapers.list

                        delegate: Item {
                            required property var modelData

                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 140
                            Layout.minimumWidth: 200
                            Layout.minimumHeight: 140

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
                                    sourceSize: Qt.size(Math.max(1, Math.floor(parent.width)), Math.max(1, Math.floor(parent.height)))

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
                                    sourceSize: Qt.size(Math.max(1, Math.floor(parent.width)), Math.max(1, Math.floor(parent.height)))

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

                                // Gradient overlay for filename with rounded bottom corners
                                Rectangle {
                                    id: filenameOverlay

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    implicitHeight: filenameText.implicitHeight + Appearance.padding.normal * 2

                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: Qt.rgba(0, 0, 0, 0)
                                        }
                                        GradientStop {
                                            position: 0.3
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        GradientStop {
                                            position: 0.7
                                            color: Qt.rgba(0, 0, 0, 0.75)
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: Qt.rgba(0, 0, 0, 0.85)
                                        }
                                    }
                                }

                                opacity: 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Component.onCompleted: {
                                    opacity = 1;
                                }
                            }

                            StyledText {
                                id: filenameText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: Appearance.padding.normal
                                anchors.rightMargin: Appearance.padding.normal
                                anchors.bottomMargin: Appearance.padding.normal

                                readonly property string fileName: {
                                    const path = modelData.relativePath || "";
                                    const parts = path.split("/");
                                    return parts.length > 0 ? parts[parts.length - 1] : path;
                                }

                                text: fileName
                                font.pointSize: Appearance.font.size.smaller
                                font.weight: 500
                                color: isCurrent ? Colours.palette.m3primary : "#FFFFFF"
                                elide: Text.ElideMiddle
                                maximumLineCount: 1

                                opacity: 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Component.onCompleted: {
                                    opacity = 1;
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
