pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services
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

        Wallpaper {
            Layout.fillWidth: true
            implicitHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Wallpapers.current
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Featured wallpaper")
            font: Tokens.font.label.medium
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Local wallpapers")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.large
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: Wallpapers.list

                ColumnLayout {
                    id: wallDelegate

                    required property FileSystemEntry modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 0 // Force uniform size
                    spacing: Tokens.spacing.small

                    Wallpaper {
                        Layout.fillWidth: true
                        implicitHeight: width
                        radius: Tokens.rounding.largeIncreased
                        source: wallDelegate.modelData.path
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: wallDelegate.modelData.name
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.builders.small.weight(Font.Medium).build()
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    component Wallpaper: StyledClippingRect {
        id: wallpaper

        property alias source: img.source

        color: Colours.tPalette.m3surfaceContainer

        Loader {
            anchors.centerIn: parent

            opacity: img.status === Image.Ready ? 0 : 1
            active: opacity > 0

            sourceComponent: StyledRect {
                implicitWidth: loadingIndicator.implicitSize + Tokens.padding.large * 2
                implicitHeight: loadingIndicator.implicitSize + Tokens.padding.large * 2

                color: Colours.palette.m3primaryContainer
                radius: Tokens.rounding.full

                LoadingIndicator {
                    id: loadingIndicator

                    anchors.centerIn: parent
                    containsIcon: true
                    implicitSize: Math.min(wallpaper.width, wallpaper.height) * 0.3
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Image {
            id: img

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(width * dpr, height * dpr);
            }
            retainWhileLoading: true
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.SlowEffects
                }
            }
        }
    }
}
