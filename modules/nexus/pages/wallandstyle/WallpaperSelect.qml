pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Browse")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: qsTr("Select an image")
                    filterLabel: qsTr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Quickshell.shellPath("assets/wallpaper.webp")
            text: qsTr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(Quickshell.shellPath("assets/wallpaper.webp"));
                root.nState.closeSubPage();
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Local wallpapers")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: {
                    const walls = Wallpapers.list;
                    const baseDir = Paths.wallsdir;
                    const categories = {};
                    for (const w of walls) {
                        if (w.parentDir !== baseDir) {
                            const category = Wallpapers.getCategoryFor(w);
                            if (category && !(category in categories))
                                categories[category] = w;
                        }
                    }
                    return Object.values(categories);
                }

                WallItem {
                    required property FileSystemEntry modelData

                    source: modelData.path
                    text: {
                        if (modelData.parentDir !== Paths.wallsdir) {
                            const category = Wallpapers.getCategoryFor(modelData);
                            return category.slice(0, 1).toUpperCase() + category.slice(1);
                        }
                        return modelData.name;
                    }
                    onClicked: {
                        if (modelData.parentDir !== Paths.wallsdir) {
                            root.nState.selectedWallpaperCategory = Wallpapers.getCategoryFor(modelData);
                            root.nState.openSubPage(2); // Category page
                        } else {
                            Wallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }
    }
}
