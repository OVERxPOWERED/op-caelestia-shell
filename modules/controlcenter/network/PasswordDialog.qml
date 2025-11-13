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
    readonly property var network: {
        // Try pendingNetwork first, then fall back to active network selection
        if (session.network.pendingNetwork) {
            return session.network.pendingNetwork;
        }
        // Fallback to active network if available
        if (session.network.active) {
            return session.network.active;
        }
        return null;
    }

    visible: session.network.showPasswordDialog
    enabled: visible
    focus: visible
    
    // Ensure network is set when dialog opens
    Component.onCompleted: {
        if (visible && !session.network.pendingNetwork && session.network.active) {
            session.network.pendingNetwork = session.network.active;
        }
    }
    
    Connections {
        target: root
        function onVisibleChanged(): void {
            if (visible && !session.network.pendingNetwork && session.network.active) {
                session.network.pendingNetwork = session.network.active;
            }
        }
    }

    Keys.onEscapePressed: {
        root.session.network.showPasswordDialog = false;
        passwordField.text = "";
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.session.network.showPasswordDialog = false;
                passwordField.text = "";
            }
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
            NumberAnimation {
                duration: 200
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
            }
        }

        Keys.onEscapePressed: {
            root.session.network.showPasswordDialog = false;
            passwordField.text = "";
        }

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

                    Component.onCompleted: {
                        if (root.visible) {
                            forceActiveFocus();
                        }
                    }

                    Connections {
                        target: root
                        function onVisibleChanged(): void {
                            if (root.visible) {
                                passwordField.forceActiveFocus();
                                passwordField.text = "";
                                Network.connectionStatus = "";
                            }
                        }
                    }
                    
                    Connections {
                        target: Network
                        function onConnectionStatusChanged(): void {
                            // Status updated, ensure it's visible
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

                Button {
                    id: cancelButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")

                    function onClicked(): void {
                        root.session.network.showPasswordDialog = false;
                        passwordField.text = "";
                    }
                }

                Button {
                    id: connectButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3primary
                    onColor: Colours.palette.m3onPrimary
                    text: qsTr("Connect")
                    enabled: passwordField.text.length > 0

                    property bool connecting: false

                    function onClicked(): void {
                        Network.connectionStatus = "";
                        
                        // Get password first
                        const password = passwordField.text;
                        
                        // Try multiple ways to get the network
                        let networkToUse = null;
                        
                        // Try 1: root.network (computed property)
                        if (root.network) {
                            networkToUse = root.network;
                        }
                        
                        // Try 2: pendingNetwork
                        if (!networkToUse && root.session.network.pendingNetwork) {
                            networkToUse = root.session.network.pendingNetwork;
                        }
                        
                        // Try 3: active network
                        if (!networkToUse && root.session.network.active) {
                            networkToUse = root.session.network.active;
                            root.session.network.pendingNetwork = networkToUse;
                        }
                        
                        // Check all conditions
                        const hasNetwork = !!networkToUse;
                        const hasPassword = password && password.length > 0;
                        const notConnecting = !connecting;
                        
                        if (hasNetwork && hasPassword && notConnecting) {
                            // Set status immediately
                            Network.connectionStatus = qsTr("Preparing to connect...");
                            
                            // Keep dialog open and track connection
                            connecting = true;
                            connectButton.enabled = false;
                            connectButton.text = qsTr("Connecting...");
                            
                            // Force immediate UI update
                            statusText.visible = true;
                            
                            // Store target SSID for later comparison
                            const ssidToConnect = networkToUse.ssid || "";
                            const bssidToConnect = networkToUse.bssid || "";
                            
                            // Store the SSID we're connecting to so we can compare later
                            // even if root.network changes
                            content.connectingToSsid = ssidToConnect;
                            
                            // Execute connection immediately
                            Network.connectToNetwork(
                                ssidToConnect, 
                                password, 
                                bssidToConnect,
                                () => {
                                    // Callback if connection fails - keep dialog open
                                    connecting = false;
                                    connectButton.enabled = true;
                                    connectButton.text = qsTr("Connect");
                                    content.connectingToSsid = "";  // Clear on failure
                                }
                            );
                            
                            // Start connection check timer immediately
                            connectionCheckTimer.checkCount = 0;
                            connectionCheckTimer.start();
                            
                            // Also check immediately after a short delay to catch quick connections
                            Qt.callLater(() => {
                                if (root.visible) {
                                    closeDialogIfConnected();
                                }
                            });
                        } else {
                            // Show error in status
                            Network.connectionStatus = qsTr("Error: Cannot connect - missing network or password");
                        }
                    }
                }
            }
            
            // Store the SSID we're connecting to when connection starts
            property string connectingToSsid: ""
            
            property string targetSsid: {
                // Track the SSID we're trying to connect to
                // Prefer explicitly stored connectingToSsid, then computed values
                if (connectingToSsid && connectingToSsid.length > 0) {
                    return connectingToSsid;
                }
                if (root.network && root.network.ssid) {
                    return root.network.ssid;
                }
                if (root.session.network.pendingNetwork && root.session.network.pendingNetwork.ssid) {
                    return root.session.network.pendingNetwork.ssid;
                }
                return "";
            }
            
            function closeDialogIfConnected(): bool {
                // Check if we're connected to the network we're trying to connect to
                const ssid = targetSsid;
                
                if (!ssid || ssid.length === 0) {
                    return false;
                }
                
                if (!Network.active) {
                    return false;
                }
                
                const activeSsid = Network.active.ssid || "";
                
                if (activeSsid === ssid) {
                    // Connection succeeded - close dialog
                    connectionCheckTimer.stop();
                    aggressiveCheckTimer.stop();
                    connectionCheckTimer.checkCount = 0;
                    connectButton.connecting = false;
                    Network.connectionStatus = "";
                    root.session.network.showPasswordDialog = false;
                    passwordField.text = "";
                    content.connectingToSsid = "";  // Clear stored SSID
                    return true;
                }
                return false;
            }
            
            Timer {
                id: connectionCheckTimer
                interval: 1000  // Check every 1 second for faster response
                repeat: true
                triggeredOnStart: false
                property int checkCount: 0
                
                onTriggered: {
                    checkCount++;
                    
                    // Try to close dialog if connected
                    const closed = content.closeDialogIfConnected();
                    if (closed) {
                        return;
                    }
                    
                    if (connectButton.connecting) {
                        // Still connecting, check again
                        // Limit to 20 checks (20 seconds total)
                        if (checkCount >= 20) {
                            connectionCheckTimer.stop();
                            connectionCheckTimer.checkCount = 0;
                            connectButton.connecting = false;
                            connectButton.enabled = true;
                            connectButton.text = qsTr("Connect");
                        }
                    } else {
                        // Not connecting anymore, stop timer
                        connectionCheckTimer.stop();
                        connectionCheckTimer.checkCount = 0;
                    }
                }
            }
            
            Connections {
                target: Network
                function onActiveChanged(): void {
                    // Check immediately when active network changes
                    if (root.visible) {
                        // Check immediately - if connected, close right away
                        if (content.closeDialogIfConnected()) {
                            return;
                        }
                        
                        // Also check after a delay in case the active network isn't fully updated yet
                        Qt.callLater(() => {
                            if (root.visible) {
                                content.closeDialogIfConnected();
                            }
                        });
                    }
                }
            }
            
            // Also check when dialog becomes visible
            Connections {
                target: root
                function onVisibleChanged(): void {
                    if (root.visible) {
                        // Check immediately when dialog opens
                        Qt.callLater(() => {
                            if (root.visible) {
                                closeDialogIfConnected();
                            }
                        });
                    }
                }
            }
            
            // Aggressive polling timer - checks every 500ms when dialog is visible and connecting
            // This ensures we catch the connection even if signals are missed
            Timer {
                id: aggressiveCheckTimer
                interval: 500
                repeat: true
                running: root.visible && connectButton.connecting
                triggeredOnStart: true
                
                onTriggered: {
                    if (root.visible && connectButton.connecting) {
                        if (content.closeDialogIfConnected()) {
                            stop();
                        }
                    } else {
                        stop();
                    }
                }
            }
        }
    }

    component Button: StyledRect {
        property color onColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text
        property alias enabled: stateLayer.enabled

        function onClicked(): void {
        }

        radius: Appearance.rounding.small
        implicitHeight: label.implicitHeight + Appearance.padding.small * 2
        opacity: enabled ? 1 : 0.5

        StateLayer {
            id: stateLayer

            enabled: parent.enabled
            color: parent.onColor

            function onClicked(): void {
                if (enabled) {
                    parent.onClicked();
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            animate: true
            color: parent.onColor
            font.pointSize: Appearance.font.size.normal
        }
    }
}

