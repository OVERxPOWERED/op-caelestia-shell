pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    signal powerRequested

    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            visible: root.hasBattery
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "battery_full"
                color: UPower.onBattery && UPower.displayDevice.percentage <= 0.2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            MaterialIcon {
                text: "bolt"
                color: Colours.palette.m3primary
                fill: 1
                fontStyle: Tokens.font.icon.small
                visible: root.charging
            }

            StyledText {
                text: `${Math.round(UPower.displayDevice.percentage * 100)}%`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }
        }

        StyledRect {
            visible: root.hasBattery
            implicitWidth: 1
            implicitHeight: Math.round(powerLayout.implicitHeight * 0.8)
            radius: width / 2
            color: Colours.palette.m3outlineVariant
        }

        StyledRect {
            implicitWidth: powerLayout.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: powerLayout.implicitHeight + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.full
            color: "transparent"

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3error
                onClicked: root.powerRequested()
            }

            RowLayout {
                id: powerLayout

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: "power_settings_new"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: qsTr("POWER OFF")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }
        }
    }
}
