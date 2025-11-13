pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.small

    RowLayout {
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        ToggleButton {
            toggled: Network.wifiEnabled
            icon: "wifi"
            accent: "Tertiary"

            onClicked: {
                Network.toggleWifi();
            }
        }

        ToggleButton {
            toggled: Network.scanning
            icon: "wifi_find"
            accent: "Secondary"

            onClicked: {
                Network.rescanWifi();
            }
        }

        ToggleButton {
            toggled: !root.session.network.active
            icon: "settings"
            accent: "Primary"

            onClicked: {
                if (root.session.network.active)
                    root.session.network.active = null;
                else {
                    root.session.network.active = view.model.get(0)?.modelData ?? null;
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Networks (%1)").arg(Network.networks.length)
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        StyledText {
            visible: Network.scanning
            text: qsTr("Scanning...")
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.small
        }
    }

    StyledText {
        text: qsTr("All available WiFi networks")
        color: Colours.palette.m3outline
    }

    StyledListView {
        id: view

        Layout.fillWidth: true
        Layout.fillHeight: true

        model: Network.networks

        spacing: Appearance.spacing.small / 2
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        delegate: StyledRect {
            required property var modelData

            anchors.left: parent.left
            anchors.right: parent.right

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.network.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Appearance.rounding.normal
            border.width: root.session.network.active === modelData ? 1 : 0
            border.color: Colours.palette.m3primary

            StateLayer {
                function onClicked(): void {
                    root.session.network.active = modelData;
                }
            }

            RowLayout {
                id: rowLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.normal

                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: modelData.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: modelData.isSecure ? "lock" : "wifi"
                        font.pointSize: Appearance.font.size.large
                        fill: modelData.active ? 1 : 0
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    text: modelData.ssid || qsTr("Unknown")
                }

                StyledText {
                    text: modelData.active ? qsTr("Connected") : (modelData.isSecure ? qsTr("Secured") : qsTr("Open"))
                    color: modelData.active ? Colours.palette.m3primary : Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    font.weight: modelData.active ? 500 : 400
                }

                StyledText {
                    text: qsTr("%1%").arg(modelData.strength)
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.active ? 1 : 0)

                    StateLayer {
                        function onClicked(): void {
                            if (modelData.active) {
                                Network.disconnectFromNetwork();
                            } else {
                                // If already connected to a different network, disconnect first
                                if (Network.active && Network.active.ssid !== modelData.ssid) {
                                    Network.disconnectFromNetwork();
                                    // Wait a moment before connecting to new network
                                    Qt.callLater(() => {
                                        connectToNetwork();
                                    });
                                } else {
                                    connectToNetwork();
                                }
                            }
                        }

                        function connectToNetwork(): void {
                            if (modelData.isSecure) {
                                // Try connecting without password first (in case it's saved)
                                Network.connectToNetworkWithPasswordCheck(
                                    modelData.ssid,
                                    modelData.isSecure,
                                    () => {
                                        // Callback: connection failed, show password dialog
                                        root.session.network.showPasswordDialog = true;
                                        root.session.network.pendingNetwork = modelData;
                                    },
                                    modelData.bssid
                                );
                            } else {
                                Network.connectToNetwork(modelData.ssid, "", modelData.bssid, null);
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        text: modelData.active ? "link_off" : "link"
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }

            implicitHeight: rowLayout.implicitHeight + Appearance.padding.normal * 2
        }
    }
}
