pragma ComponentBehavior: Bound

import ".."
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

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: root.network?.isSecure ? "lock" : "wifi"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: root.network?.ssid ?? qsTr("Unknown")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Connection settings for this network")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

                    Toggle {
                        label: qsTr("Connected")
                        checked: root.network?.active ?? false
                        toggle.onToggled: {
                            if (checked) {
                                // If already connected to a different network, disconnect first
                                if (Network.active && Network.active.ssid !== root.network.ssid) {
                                    Network.disconnectFromNetwork();
                                    // Wait a moment before connecting to new network
                                    Qt.callLater(() => {
                                        connectToNetwork();
                                    });
                                } else {
                                    connectToNetwork();
                                }
                            } else {
                                Network.disconnectFromNetwork();
                            }
                        }

                        function connectToNetwork(): void {
                            if (root.network.isSecure) {
                                // Try connecting without password first (in case it's saved)
                                Network.connectToNetworkWithPasswordCheck(
                                    root.network.ssid,
                                    root.network.isSecure,
                                    () => {
                                        // Callback: connection failed, show password dialog
                                        root.session.network.showPasswordDialog = true;
                                        root.session.network.pendingNetwork = root.network;
                                    }
                                );
                            } else {
                                Network.connectToNetwork(root.network.ssid, "");
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Network properties")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Additional information")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkProps.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkProps

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("SSID")
                    }

                    StyledText {
                        text: root.network?.ssid ?? qsTr("Unknown")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("BSSID")
                    }

                    StyledText {
                        text: root.network?.bssid ?? qsTr("Unknown")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Signal strength")
                    }

                    StyledText {
                        text: root.network ? qsTr("%1%").arg(root.network.strength) : qsTr("N/A")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Frequency")
                    }

                    StyledText {
                        text: root.network ? qsTr("%1 MHz").arg(root.network.frequency) : qsTr("N/A")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Security")
                    }

                    StyledText {
                        text: root.network ? (root.network.isSecure ? root.network.security : qsTr("Open")) : qsTr("N/A")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Network connection details")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: connectionInfo.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: connectionInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("IP Address")
                    }

                    StyledText {
                        text: Network.wirelessDeviceDetails?.ipAddress || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Subnet Mask")
                    }

                    StyledText {
                        text: Network.wirelessDeviceDetails?.subnet || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Gateway")
                    }

                    StyledText {
                        text: Network.wirelessDeviceDetails?.gateway || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("DNS Servers")
                    }

                    StyledText {
                        text: (Network.wirelessDeviceDetails && Network.wirelessDeviceDetails.dns && Network.wirelessDeviceDetails.dns.length > 0) ? Network.wirelessDeviceDetails.dns.join(", ") : qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        wrapMode: Text.Wrap
                        Layout.maximumWidth: parent.width
                    }
                }
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }
}

