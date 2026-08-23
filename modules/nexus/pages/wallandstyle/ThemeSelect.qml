pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils
import qs.modules.launcher.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Themes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        SectionHeader {
            first: true
            text: qsTr("Available themes")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor(root.cappedWidth / 220))
            columnSpacing: Tokens.spacing.medium
            rowSpacing: Tokens.spacing.medium

            Repeater {
                model: ThemeManager.list

                StyledRect {
                    id: themeCard

                    required property var modelData

                    readonly property bool isActive: GlobalConfig.paths.themeName === modelData.folder

                    Layout.fillWidth: true
                    implicitHeight: 180
                    radius: Tokens.rounding.large
                    color: isActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
                    border.width: isActive ? 2 : 1
                    border.color: isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        // Wallpaper preview thumbnail
                        StyledClippingRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Tokens.rounding.medium
                            color: Colours.palette.m3surfaceContainerLowest

                            FadeImage {
                                anchors.fill: parent
                                source: themeCard.modelData.wallpaperPath
                                fillMode: Image.PreserveAspectCrop
                            }

                            // Active check badge
                            StyledRect {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Tokens.padding.extraSmall
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: Tokens.rounding.full
                                visible: themeCard.isActive
                                color: Colours.palette.m3primary

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "check"
                                    color: Colours.palette.m3onPrimary
                                    fontStyle: Tokens.font.icon.small
                                }
                            }
                        }

                        // Theme title
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "palette"
                                color: themeCard.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: themeCard.modelData.name
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                                color: themeCard.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }
                    }

                    CustomMouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            GlobalConfig.paths.themeName = themeCard.modelData.folder;
                            GlobalConfig.save();
                            if (themeCard.modelData.wallpaperPath)
                                Wallpapers.setWallpaper(themeCard.modelData.wallpaperPath);
                        }
                    }
                }
            }
        }

        // Custom paths
        SectionHeader {
            text: qsTr("Wallpaper directory")
        }

        TextFieldRow {
            first: true
            last: true
            label: qsTr("Wallpapers folder")
            subtext: qsTr("Directory used for wallpapers and random switcher")
            value: GlobalConfig.paths.wallpaperDir
            placeholderText: "/home/user/Pictures/Wallpapers"
            onEditingFinished: value => {
                if (value.trim().length > 0)
                    GlobalConfig.paths.wallpaperDir = value.trim();
            }
        }

        // How to create custom themes guide card
        SectionHeader {
            text: qsTr("Create your own theme")
        }

        StyledRect {
            Layout.fillWidth: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant
            implicitHeight: guideCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: guideCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small
                    MaterialIcon {
                        text: "palette"
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        text: qsTr("Theme Package Structure")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("1. Create a folder in <b>assets/themes/&lt;ThemeName&gt;/</b>\n2. Add your wallpaper as <b>wallpaper.jpg</b> (or <b>wallpaper.png</b>)\n3. (Optional) Add theme GIFs inside <b>visuals/</b> (e.g. media.gif, session.gif)\n4. Your new theme appears automatically here and via <b>:theme</b> in the launcher!")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
