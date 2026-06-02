pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledRect {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: Tokens.font.body.medium.pointSize * 2

    implicitHeight: layout.implicitHeight + layout.anchors.topMargin + layout.anchors.margins
    radius: Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        anchors.topMargin: Tokens.padding.extraLarge
        anchors.bottomMargin: Tokens.padding.extraLarge

        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: prompt.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: prompt.implicitHeight + Tokens.padding.small * 2

                color: Colours.palette.m3primary
                radius: Tokens.rounding.medium

                MonoText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    color: Colours.palette.m3onPrimary
                }
            }

            MonoText {
                Layout.fillWidth: true
                text: "caelestiafetch.sh"
                elide: Text.ElideRight
            }

            WrappedLoader {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.preferredHeight: 0
                active: !iconLoader.active

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }
        }

        RowLayout {
            Layout.topMargin: -Tokens.spacing.extraSmall
            Layout.bottomMargin: Tokens.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            WrappedLoader {
                id: iconLoader

                Layout.fillHeight: true
                active: root.width > 320

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.medium
                Layout.bottomMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                Repeater {
                    model: {
                        const items = [];
                        const hasBatt = UPower.displayDevice.isLaptopBattery;
                        const rHeight = root.rootHeight;

                        if (!hasBatt && rHeight > 200)
                            items.push(`OS  : ${SysInfo.osPrettyName || SysInfo.osName}`);

                        if (rHeight > (hasBatt ? 200 : 110))
                            items.push(`WM  : ${SysInfo.wm}`);

                        if (!hasBatt || rHeight > 110)
                            items.push(`USER: ${SysInfo.user}`);

                        items.push(`UP  : ${SysInfo.uptime}`);

                        if (hasBatt)
                            items.push(`BATT: ${[UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state) ? "(+) " : ""}${Math.round(UPower.displayDevice.percentage * 100)}%`);

                        return items;
                    }

                    MonoText {
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                }
            }
        }

        WrappedLoader {
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > 180

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: CUtils.clamp(Math.floor((layout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, 8)

                    StyledRect {
                        required property int index

                        implicitWidth: implicitHeight
                        implicitHeight: root.cBoxSize
                        color: Colours.palette[`term${index}`]
                        radius: Tokens.rounding.medium
                    }
                }
            }
        }
    }

    Component {
        id: caelestiaLogo

        Logo {
            width: height
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: Colours.palette.m3primary
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component MonoText: StyledText {
        font: root.width > 400 ? Tokens.font.mono.medium : Tokens.font.mono.small
    }
}
