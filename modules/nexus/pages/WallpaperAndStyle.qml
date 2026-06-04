pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

ColumnLayout {
    id: root

    required property NexusState nState
    readonly property int cappedWidth: Math.min(800, width)

    spacing: Tokens.spacing.large

    StyledText {
        text: qsTr("Wallpaper & style")
        font: Tokens.font.title.large
    }

    StyledClippingRect {
        id: wallWrapper

        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraLarge
        implicitWidth: {
            const screen = root.nState.screen;
            return implicitHeight / screen.height * screen.width;
        }
        implicitHeight: {
            const screen = root.nState.screen;
            const cWidth = root.cappedWidth;
            return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
        }

        color: Colours.palette.m3surfaceContainer
        radius: Tokens.rounding.large

        Loader {
            anchors.centerIn: parent

            opacity: wallImg.status === Image.Ready ? 0 : 1
            active: opacity > 0

            sourceComponent: StyledRect {
                implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                color: Colours.palette.m3primaryContainer
                radius: Tokens.rounding.full

                LoadingIndicator {
                    id: wallLoadingIndicator

                    anchors.centerIn: parent
                    containsIcon: true
                    implicitSize: wallWrapper.implicitHeight * 0.4
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Image {
            id: wallImg

            anchors.fill: parent
            source: Wallpapers.current
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

    ButtonRow {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.small

        IconTextButton {
            icon: "wallpaper"
            text: qsTr("Wallpapers")
            font: Tokens.font.body.large
            isRound: true
            shapeMorph: true
            type: IconTextButton.Tonal
            horizontalPadding: Tokens.padding.extraLarge
            verticalPadding: Tokens.padding.medium
            onClicked: ; // TODO
        }

        IconTextButton {
            icon: "palette"
            text: qsTr("Colours")
            font: Tokens.font.body.large
            isRound: true
            shapeMorph: true
            type: IconTextButton.Tonal
            horizontalPadding: Tokens.padding.extraLarge
            verticalPadding: Tokens.padding.medium
            onClicked: ; // TODO
        }
    }

    ToggleRow {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.cappedWidth

        first: true
        text: qsTr("Display wallpaper")
        checked: Config.background.wallpaperEnabled
        onToggled: GlobalConfig.background.wallpaperEnabled = checked
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.cappedWidth

        text: qsTr("Transparency")
        subtext: qsTr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
        checked: Colours.transparency.enabled
        onToggled: GlobalConfig.appearance.transparency.enabled = checked
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.cappedWidth

        last: true
        text: qsTr("Dark theme")
        checked: !Colours.light
        onToggled: Colours.setMode(checked ? "dark" : "light")
    }

    Item {
        Layout.fillHeight: true
    }
}
