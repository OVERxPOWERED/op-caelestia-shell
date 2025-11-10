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
import Caelestia.Models
import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

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
                text: qsTr("Theme mode")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Light or dark theme")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: modeToggle.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

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

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Color variant")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Material theme variant")
                color: Colours.palette.m3outline
            }

            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true

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
                            Quickshell.execDetached(["caelestia", "scheme", "set", "-v", modelData.variant]);
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

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Color scheme")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Available color schemes")
                color: Colours.palette.m3outline
            }

            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true

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
                            Quickshell.execDetached(["caelestia", "scheme", "set", "-n", modelData.name, "-f", modelData.flavour]);
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

                        Item {
                            readonly property real itemHeight: schemeRow.implicitHeight || 50
                            Layout.preferredWidth: itemHeight * 0.8
                            Layout.preferredHeight: itemHeight * 0.8

                            StyledRect {
                                id: preview

                                anchors.verticalCenter: parent.verticalCenter

                                border.width: 1
                                border.color: Qt.alpha(`#${modelData.colours?.outline}`, 0.5)

                                color: `#${modelData.colours?.surface}`
                                radius: Appearance.rounding.full
                                implicitWidth: parent.itemHeight * 0.8
                                implicitHeight: parent.itemHeight * 0.8

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
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: modelData.name
                                font.weight: isCurrent ? 500 : 400
                            }

                            StyledText {
                                text: modelData.flavour
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                            }
                        }

                        MaterialIcon {
                            visible: isCurrent
                            text: "check"
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.large
                        }
                    }

                    implicitHeight: schemeRow.implicitHeight + Appearance.padding.normal * 2
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


