pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Network")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Wi-Fi")
            font: Tokens.font.title.medium
            checked: Network.wifiEnabled
            onToggled: Network.enableWifi(checked)

            horizontalPadding: Tokens.padding.largeIncreased
            verticalPadding: Tokens.padding.medium
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: networkList.implicitHeight + networkList.anchors.margins * 2
            radius: Tokens.rounding.extraSmall
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: networkList

                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: Network.networks

                    StateLayer {
                        id: network

                        required property Network.AccessPoint modelData

                        Layout.fillWidth: true
                        implicitHeight: networkLayout.implicitHeight + networkLayout.anchors.margins * 2
                        radius: Tokens.rounding.extraSmall
                        anchors.fill: undefined

                        RowLayout {
                            id: networkLayout

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: Icons.getNetworkIcon(network.modelData.strength)
                                color: network.modelData.active ? Colours.palette.m3primary : Colours.tPalette.m3onSurfaceVariant
                                font: Tokens.font.icon.medium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: network.modelData.ssid
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Security: %1").arg(network.modelData.security)
                                    color: Colours.tPalette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }

                            MaterialIcon {
                                visible: network.modelData.isSecure
                                text: network.modelData.active ? "settings" : "lock"
                                color: network.modelData.active ? Colours.palette.m3primary : Colours.tPalette.m3onSurfaceVariant
                                font: Tokens.font.icon.medium
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            bottomLeftRadius: Tokens.rounding.extraLarge
            bottomRightRadius: Tokens.rounding.extraLarge
            radius: Tokens.rounding.extraSmall

            implicitHeight: addNetworkLayout.implicitHeight + addNetworkLayout.anchors.margins * 2
            color: Colours.tPalette.m3surfaceContainer

            StateLayer {}

            RowLayout {
                id: addNetworkLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "add"
                    color: Colours.tPalette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add network")
                    color: Colours.tPalette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
