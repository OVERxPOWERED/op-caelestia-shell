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

    Component.onCompleted: {
        updateDeviceDetails();
        checkSavedProfile();
    }

    onNetworkChanged: {
        updateDeviceDetails();
        checkSavedProfile();
    }

    function checkSavedProfile(): void {
        if (network && network.ssid) {
            Nmcli.loadSavedConnections(() => {});
        }
    }

    Connections {
        target: Nmcli
        function onActiveChanged() {
            updateDeviceDetails();
        }
    }

    function updateDeviceDetails(): void {
        if (network && Nmcli.active && Nmcli.active.ssid === network.ssid) {
            Nmcli.getWirelessDeviceDetails("", () => {});
        } else {
            Nmcli.wirelessDeviceDetails = null;
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
                            handleConnect();
                        } else {
                            Nmcli.disconnectFromNetwork();
                        }
                    }
                }

                SimpleButton {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    visible: {
                        if (!root.network || !root.network.ssid) {
                            return false;
                        }
                        return Nmcli.hasSavedProfile(root.network.ssid);
                    }
                    color: Colours.palette.m3errorContainer
                    onColor: Colours.palette.m3onErrorContainer
                    text: qsTr("Forget Network")

                    onClicked: {
                        if (root.network && root.network.ssid) {
                            if (root.network.active) {
                                Nmcli.disconnectFromNetwork();
                            }
                            Nmcli.forgetNetwork(root.network.ssid, () => {});
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
                    deviceDetails: Nmcli.wirelessDeviceDetails
                }
            }

        }
    }

    function handleConnect(): void {
        if (Nmcli.active && Nmcli.active.ssid !== root.network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(() => {
                connectToNetwork();
            });
        } else {
            connectToNetwork();
        }
    }

    function connectToNetwork(): void {
        if (root.network.isSecure) {
            const hasSavedProfile = Nmcli.hasSavedProfile(root.network.ssid);

            if (hasSavedProfile) {
                Nmcli.connectToNetwork(root.network.ssid, "", root.network.bssid, null);
            } else {
                Nmcli.connectToNetworkWithPasswordCheck(
                    root.network.ssid,
                    root.network.isSecure,
                    (result) => {
                        if (result.needsPassword) {
                            if (Nmcli.pendingConnection) {
                                Nmcli.connectionCheckTimer.stop();
                                Nmcli.immediateCheckTimer.stop();
                                Nmcli.immediateCheckTimer.checkCount = 0;
                                Nmcli.pendingConnection = null;
                            }
                            root.session.network.showPasswordDialog = true;
                            root.session.network.pendingNetwork = root.network;
                        }
                    },
                    root.network.bssid
                );
            }
        } else {
            Nmcli.connectToNetwork(root.network.ssid, "", root.network.bssid, null);
        }
    }
}