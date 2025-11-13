pragma ComponentBehavior: Bound

import ".."
import "."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var network: session.network.active
    
    readonly property var connectionHelper: WirelessConnectionHelper {
        session: root.session
    }

    Component.onCompleted: {
        if (network && network.active) {
            Network.updateWirelessDeviceDetails();
        }
    }

    onNetworkChanged: {
        if (network && network.active) {
            Network.updateWirelessDeviceDetails();
        } else {
            Network.wirelessDeviceDetails = null;
        }
    }

    Connections {
        target: Network
        function onActiveChanged() {
            if (root.network && root.network.active && Network.active && Network.active.ssid === root.network.ssid) {
                Network.updateWirelessDeviceDetails();
            } else if (!root.network || !root.network.active) {
                Network.wirelessDeviceDetails = null;
            }
        }
    }

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: layout.height

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            ConnectionHeader {
                icon: root.network?.isSecure ? "lock" : "wifi"
                title: root.network?.ssid ?? qsTr("Unknown")
            }

            SectionHeader {
                title: qsTr("Connection status")
                description: qsTr("Connection settings for this network")
            }

            SectionContainer {
                ToggleRow {
                    label: qsTr("Connected")
                    checked: root.network?.active ?? false
                    toggle.onToggled: {
                        if (checked) {
                            root.connectionHelper.connectToNetwork(root.network);
                        } else {
                            Network.disconnectFromNetwork();
                        }
                    }
                }

                SimpleButton {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    visible: root.network && root.network.ssid && Network.savedConnections.includes(root.network.ssid)
                    color: Colours.palette.m3errorContainer
                    onColor: Colours.palette.m3onErrorContainer
                    text: qsTr("Forget Network")
                    
                    onClicked: {
                        if (root.network && root.network.ssid) {
                            // Disconnect first if connected
                            if (root.network.active) {
                                Network.disconnectFromNetwork();
                            }
                            // Delete the connection profile
                            Network.forgetNetwork(root.network.ssid);
                        }
                    }
                }
            }

            SectionHeader {
                title: qsTr("Network properties")
                description: qsTr("Additional information")
            }

            SectionContainer {
                contentSpacing: Appearance.spacing.small / 2

                PropertyRow {
                    label: qsTr("SSID")
                    value: root.network?.ssid ?? qsTr("Unknown")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("BSSID")
                    value: root.network?.bssid ?? qsTr("Unknown")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("Signal strength")
                    value: root.network ? qsTr("%1%").arg(root.network.strength) : qsTr("N/A")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("Frequency")
                    value: root.network ? qsTr("%1 MHz").arg(root.network.frequency) : qsTr("N/A")
                }

                PropertyRow {
                    showTopMargin: true
                    label: qsTr("Security")
                    value: root.network ? (root.network.isSecure ? root.network.security : qsTr("Open")) : qsTr("N/A")
                }
            }

            SectionHeader {
                title: qsTr("Connection information")
                description: qsTr("Network connection details")
            }

            SectionContainer {
                ConnectionInfoSection {
                    deviceDetails: Network.wirelessDeviceDetails
                }
            }

        }
    }
}

