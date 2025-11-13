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
    
    readonly property var network: {
        // Prefer pendingNetwork, then active network
        if (session.network.pendingNetwork) {
            return session.network.pendingNetwork;
        }
        if (session.network.active) {
            return session.network.active;
        }
        return null;
    }

    visible: session.network.showPasswordDialog
    enabled: visible
    focus: visible

    Keys.onEscapePressed: {
        closeDialog();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: closeDialog();
        }
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent

        implicitWidth: 400
        implicitHeight: content.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surface
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Behavior on scale {
            NumberAnimation { duration: 200 }
        }

        Keys.onEscapePressed: closeDialog();

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                font.pointSize: Appearance.font.size.extraLarge * 2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enter password")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.network ? qsTr("Network: %1").arg(root.network.ssid) : ""
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                id: statusText
                
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                visible: Network.connectionStatus.length > 0 || connectButton.connecting
                text: {
                    if (Network.connectionStatus.length > 0) {
                        return Network.connectionStatus;
                    } else if (connectButton.connecting) {
                        return qsTr("Connecting...");
                    }
                    return "";
                }
                color: {
                    const status = Network.connectionStatus;
                    if (status.includes("Error") || status.includes("error") || status.includes("failed")) {
                        return Colours.palette.m3error;
                    } else if (status.includes("successful") || status.includes("Connected") || status.includes("success")) {
                        return Colours.palette.m3primary;
                    }
                    return Colours.palette.m3onSurfaceVariant;
                }
                font.pointSize: Appearance.font.size.small
                font.weight: (Network.connectionStatus.includes("Error") || Network.connectionStatus.includes("error")) ? 500 : 400
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width - Appearance.padding.large * 2
            }

            Item {
                Layout.topMargin: Appearance.spacing.large
                Layout.fillWidth: true
                implicitHeight: passwordField.implicitHeight + Appearance.padding.normal * 2

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                    Behavior on border.color {
                        CAnim {}
                    }
                }

                StyledTextField {
                    id: passwordField

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal

                    echoMode: TextField.Password
                    placeholderText: qsTr("Password")

                    Connections {
                        target: root
                        function onVisibleChanged(): void {
                            if (root.visible) {
                                passwordField.forceActiveFocus();
                                passwordField.text = "";
                                Network.clearConnectionStatus();
                            }
                        }
                    }

                    Keys.onReturnPressed: {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                    }
                    Keys.onEnterPressed: {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Appearance.spacing.normal
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                SimpleButton {
                    id: cancelButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")

                    onClicked: closeDialog();
                }

                SimpleButton {
                    id: connectButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3primary
                    onColor: Colours.palette.m3onPrimary
                    text: qsTr("Connect")
                    enabled: passwordField.text.length > 0 && !connecting

                    property bool connecting: false

                    onClicked: {
                        if (!root.network || connecting) {
                            return;
                        }

                        const password = passwordField.text;
                        if (!password || password.length === 0) {
                            return;
                        }

                        // Set connecting state
                        connecting = true;
                        enabled = false;
                        text = qsTr("Connecting...");
                        Network.clearConnectionStatus();

                        // Connect to network
                        Network.connectToNetwork(
                            root.network.ssid,
                            password,
                            root.network.bssid || "",
                            null
                        );

                        // Start monitoring connection
                        connectionMonitor.start();
                    }
                }
            }
        }
    }

    function checkConnectionStatus(): void {
        if (!root.visible || !connectButton.connecting) {
            return;
        }

        // Check if we're connected to the target network
        if (root.network && Network.active && Network.active.ssid === root.network.ssid) {
            // Successfully connected
            connectionMonitor.stop();
            connectButton.connecting = false;
            connectButton.text = qsTr("Connect");
            closeDialog();
            return;
        }

        // Check for connection errors
        const status = Network.connectionStatus;
        if (status.includes("Error") || status.includes("error") || status.includes("failed")) {
            // Connection failed
            connectionMonitor.stop();
            connectButton.connecting = false;
            connectButton.enabled = true;
            connectButton.text = qsTr("Connect");
        }
    }

    Timer {
        id: connectionMonitor
        interval: 1000
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            checkConnectionStatus();
        }
    }

    Connections {
        target: Network
        function onActiveChanged() {
            if (root.visible) {
                checkConnectionStatus();
            }
        }
    }

    function closeDialog(): void {
        session.network.showPasswordDialog = false;
        passwordField.text = "";
        connectButton.connecting = false;
        connectButton.text = qsTr("Connect");
        connectionMonitor.stop();
        Network.clearConnectionStatus();
    }
}

