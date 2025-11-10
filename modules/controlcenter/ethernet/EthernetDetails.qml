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
    readonly property var device: session.ethernet.active

    Component.onCompleted: {
        if (device && device.interface) {
            Network.updateEthernetDeviceDetails(device.interface);
        }
    }

    onDeviceChanged: {
        if (device && device.interface) {
            Network.updateEthernetDeviceDetails(device.interface);
        } else {
            Network.ethernetDeviceDetails = null;
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
                text: "cable"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: root.device?.interface ?? qsTr("Unknown")
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
                text: qsTr("Connection settings for this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

                    Toggle {
                        label: qsTr("Connected")
                        checked: root.device?.connected ?? false
                        toggle.onToggled: {
                            if (checked) {
                                // Use connection name if available, otherwise use interface
                                Network.connectEthernet(root.device?.connection || "", root.device?.interface || "");
                            } else {
                                if (root.device?.connection) {
                                    Network.disconnectEthernet(root.device.connection);
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Device properties")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Additional information")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceProps.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceProps

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("Interface")
                    }

                    StyledText {
                        text: root.device?.interface ?? qsTr("Unknown")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Connection")
                    }

                    StyledText {
                        text: root.device?.connection || qsTr("Not connected")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("State")
                    }

                    StyledText {
                        text: root.device?.state ?? qsTr("Unknown")
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
                        text: Network.ethernetDeviceDetails?.ipAddress || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Subnet Mask")
                    }

                    StyledText {
                        text: Network.ethernetDeviceDetails?.subnet || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Gateway")
                    }

                    StyledText {
                        text: Network.ethernetDeviceDetails?.gateway || qsTr("Not available")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("DNS Servers")
                    }

                    StyledText {
                        text: (Network.ethernetDeviceDetails && Network.ethernetDeviceDetails.dns && Network.ethernetDeviceDetails.dns.length > 0) ? Network.ethernetDeviceDetails.dns.join(", ") : qsTr("Not available")
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
























