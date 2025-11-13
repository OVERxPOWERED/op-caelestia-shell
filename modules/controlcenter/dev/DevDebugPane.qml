pragma ComponentBehavior: Bound

import "."
import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.config
import qs.services
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property DevSession session

    anchors.fill: parent

    // Track last failed connection
    property string lastFailedSsid: ""

    // Connect to connection failure signal
    Connections {
        target: Nmcli
        function onConnectionFailed(ssid: string) {
            root.lastFailedSsid = ssid;
            appendLog("Connection failed signal received for: " + ssid);
        }
    }

    StyledFlickable {
        id: flickable

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentLayout.implicitHeight

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: flickable
        }

        ColumnLayout {
            id: contentLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Debug Panel")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

        // Action Buttons Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: buttonsLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: buttonsLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Actions")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    TextButton {
                        text: qsTr("Clear Log")
                        onClicked: {
                            debugOutput.text = "";
                            appendLog("Debug log cleared");
                        }
                    }

                    TextButton {
                        text: qsTr("Test Action")
                        onClicked: {
                            appendLog("Test action executed at " + new Date().toLocaleTimeString());
                        }
                    }

                    TextButton {
                        text: qsTr("Log Network State")
                        onClicked: {
                            appendLog("Network state:");
                            appendLog("  Active: " + (root.session.network.active ? "Yes" : "No"));
                        }
                    }

                    TextButton {
                        text: qsTr("Get Device Status")
                        onClicked: {
                            appendLog("Getting device status...");
                            try {
                                Nmcli.getDeviceStatus((output) => {
                                    if (!output) {
                                        appendLog("  Error: No output received");
                                        return;
                                    }
                                    appendLog("Device Status:");
                                    const lines = output.trim().split("\n");
                                    if (lines.length === 0 || (lines.length === 1 && lines[0].length === 0)) {
                                        appendLog("  No devices found");
                                    } else {
                                        for (const line of lines) {
                                            if (line.length > 0) {
                                                appendLog("  " + line);
                                            }
                                        }
                                    }
                                });
                            } catch (e) {
                                appendLog("Error: " + e);
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Get Wireless Interfaces")
                        onClicked: {
                            appendLog("Getting wireless interfaces...");
                            Nmcli.getWirelessInterfaces((interfaces) => {
                                appendLog("Wireless Interfaces: " + interfaces.length);
                                for (const iface of interfaces) {
                                    appendLog(`  ${iface.device}: ${iface.state} (${iface.connection})`);
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Get Ethernet Interfaces")
                        onClicked: {
                            appendLog("Getting ethernet interfaces...");
                            Nmcli.getEthernetInterfaces((interfaces) => {
                                appendLog("Ethernet Interfaces: " + interfaces.length);
                                for (const iface of interfaces) {
                                    appendLog(`  ${iface.device}: ${iface.state} (${iface.connection})`);
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Refresh Status")
                        onClicked: {
                            appendLog("Refreshing connection status...");
                            Nmcli.refreshStatus((status) => {
                                appendLog("Connection Status:");
                                appendLog("  Connected: " + (status.connected ? "Yes" : "No"));
                                appendLog("  Interface: " + (status.interface || "None"));
                                appendLog("  Connection: " + (status.connection || "None"));
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Check Interface")
                        onClicked: {
                            appendLog("Checking interface connection status...");
                            // Check first wireless interface if available
                            if (Nmcli.wirelessInterfaces.length > 0) {
                                const iface = Nmcli.wirelessInterfaces[0].device;
                                appendLog("Checking: " + iface);
                                Nmcli.isInterfaceConnected(iface, (connected) => {
                                    appendLog(`  ${iface}: ${connected ? "Connected" : "Disconnected"}`);
                                });
                            } else {
                                appendLog("No wireless interfaces found");
                            }
                        }
                    }
                }
            }
        }

        // WiFi Radio Control Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: wifiRadioLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: wifiRadioLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("WiFi Radio Control")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Status: ") + (Nmcli.wifiEnabled ? qsTr("Enabled") : qsTr("Disabled"))
                        color: Nmcli.wifiEnabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Toggle WiFi")
                        onClicked: {
                            appendLog("Toggling WiFi radio...");
                            Nmcli.toggleWifi((result) => {
                                if (result.success) {
                                    appendLog("WiFi radio toggled: " + (Nmcli.wifiEnabled ? "Enabled" : "Disabled"));
                                } else {
                                    appendLog("Failed to toggle WiFi: " + (result.error || "Unknown error"));
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Enable")
                        onClicked: {
                            appendLog("Enabling WiFi radio...");
                            Nmcli.enableWifi(true, (result) => {
                                if (result.success) {
                                    appendLog("WiFi radio enabled");
                                } else {
                                    appendLog("Failed to enable WiFi: " + (result.error || "Unknown error"));
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Disable")
                        onClicked: {
                            appendLog("Disabling WiFi radio...");
                            Nmcli.enableWifi(false, (result) => {
                                if (result.success) {
                                    appendLog("WiFi radio disabled");
                                } else {
                                    appendLog("Failed to disable WiFi: " + (result.error || "Unknown error"));
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Check Status")
                        onClicked: {
                            appendLog("Checking WiFi radio status...");
                            Nmcli.getWifiStatus((enabled) => {
                                appendLog("WiFi radio status: " + (enabled ? "Enabled" : "Disabled"));
                            });
                        }
                    }
                }
            }
        }

        // Network List Management Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: networkListLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: networkListLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Network List Management")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Networks: %1").arg(Nmcli.networks.length)
                    }

                    StyledText {
                        visible: Nmcli.active
                        text: qsTr("Active: %1").arg(Nmcli.active.ssid)
                        color: Colours.palette.m3primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh Networks")
                        onClicked: {
                            appendLog("Refreshing network list...");
                            Nmcli.getNetworks((networks) => {
                                appendLog("Found " + networks.length + " networks");
                                if (Nmcli.active) {
                                    appendLog("Active network: " + Nmcli.active.ssid + " (Signal: " + Nmcli.active.strength + "%, Security: " + (Nmcli.active.isSecure ? Nmcli.active.security : "Open") + ")");
                                } else {
                                    appendLog("No active network");
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("List All Networks")
                        onClicked: {
                            appendLog("Network list:");
                            if (Nmcli.networks.length === 0) {
                                appendLog("  No networks found");
                            } else {
                                for (let i = 0; i < Nmcli.networks.length; i++) {
                                    const net = Nmcli.networks[i];
                                    const activeMark = net.active ? " [ACTIVE]" : "";
                                    appendLog(`  ${i + 1}. ${net.ssid}${activeMark}`);
                                    appendLog(`     Signal: ${net.strength}%, Freq: ${net.frequency}MHz, Security: ${net.isSecure ? net.security : "Open"}`);
                                    if (net.bssid) {
                                        appendLog(`     BSSID: ${net.bssid}`);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Interface Selector Section (for future features)
        Item {
            Layout.fillWidth: true
            implicitHeight: interfaceSelectorContainer.implicitHeight
            z: 10  // Ensure dropdown menu appears above other elements

            StyledRect {
                id: interfaceSelectorContainer

                anchors.fill: parent
                implicitHeight: interfaceSelectorLayout.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: interfaceSelectorLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: qsTr("Interface Selector")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        SplitButton {
                            id: interfaceSelector

                            type: SplitButton.Tonal
                            fallbackText: qsTr("Select Interface")
                            fallbackIcon: "settings_ethernet"
                            menuItems: interfaceList.instances
                            menuOnTop: true  // Position menu above button to avoid being covered

                            property string selectedInterface: ""

                            menu.onItemSelected: (item) => {
                                interfaceSelector.selectedInterface = item.modelData.device;
                                appendLog("Selected interface: " + item.modelData.device + " (" + item.modelData.type + ")");
                            }

                            Variants {
                                id: interfaceList

                                model: interfaceSelector.interfaces

                                MenuItem {
                                    required property var modelData

                                    text: modelData.device + " (" + modelData.type + ")"
                                    icon: modelData.type === "wifi" ? "wifi" : "settings_ethernet"
                                }
                            }

                            property list<var> interfaces: []

                            function refreshInterfaces(): void {
                                appendLog("Refreshing interface list...");
                                Nmcli.getAllInterfaces((interfaces) => {
                                    interfaceSelector.interfaces = interfaces;
                                    if (interfaces.length > 0) {
                                        // Wait for Variants to create instances, then set active
                                        Qt.callLater(() => {
                                            if (interfaceList.instances.length > 0) {
                                                interfaceSelector.active = interfaceList.instances[0];
                                                interfaceSelector.selectedInterface = interfaces[0].device;
                                            }
                                        });
                                        appendLog("Found " + interfaces.length + " interfaces");
                                    } else {
                                        interfaceSelector.selectedInterface = "";
                                        appendLog("No interfaces found");
                                    }
                                });
                            }

                            Component.onCompleted: {
                                // Ensure menu appears above other elements
                                menu.z = 100;
                            }
                        }

                        TextButton {
                            text: qsTr("Refresh")
                            onClicked: {
                                interfaceSelector.refreshInterfaces();
                            }
                        }

                        TextButton {
                            text: qsTr("Up")
                            enabled: interfaceSelector.selectedInterface.length > 0
                            onClicked: {
                                if (interfaceSelector.selectedInterface) {
                                    appendLog("Bringing interface up: " + interfaceSelector.selectedInterface);
                                    Nmcli.bringInterfaceUp(interfaceSelector.selectedInterface, (result) => {
                                        if (result.success) {
                                            appendLog("Interface up: Success");
                                        } else {
                                            appendLog("Interface up: Failed (exit code: " + result.exitCode + ")");
                                            if (result.error && result.error.length > 0) {
                                                appendLog("Error: " + result.error);
                                            }
                                        }
                                        // Refresh interface list after bringing up
                                        Qt.callLater(() => {
                                            interfaceSelector.refreshInterfaces();
                                        }, 500);
                                    });
                                }
                            }
                        }

                        TextButton {
                            text: qsTr("Down")
                            enabled: interfaceSelector.selectedInterface.length > 0
                            onClicked: {
                                if (interfaceSelector.selectedInterface) {
                                    appendLog("Bringing interface down: " + interfaceSelector.selectedInterface);
                                    Nmcli.bringInterfaceDown(interfaceSelector.selectedInterface, (result) => {
                                        if (result.success) {
                                            appendLog("Interface down: Success");
                                        } else {
                                            appendLog("Interface down: Failed (exit code: " + result.exitCode + ")");
                                            if (result.error && result.error.length > 0) {
                                                appendLog("Error: " + result.error);
                                            }
                                        }
                                        // Refresh interface list after bringing down
                                        Qt.callLater(() => {
                                            interfaceSelector.refreshInterfaces();
                                        }, 500);
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        // Wireless SSID Selector Section
        Item {
            Layout.fillWidth: true
            implicitHeight: ssidSelectorContainer.implicitHeight
            z: 10  // Ensure dropdown menu appears above other elements

            StyledRect {
                id: ssidSelectorContainer

                anchors.fill: parent
                implicitHeight: ssidSelectorLayout.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: ssidSelectorLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Wireless SSID Selector")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    SplitButton {
                        id: ssidSelector

                        type: SplitButton.Tonal
                        fallbackText: qsTr("Select SSID")
                        fallbackIcon: "wifi"
                        menuItems: ssidList.instances
                        menuOnTop: true

                        property string selectedSSID: ""

                        menu.onItemSelected: (item) => {
                            ssidSelector.selectedSSID = item.modelData.ssid;
                            appendLog("Selected SSID: " + item.modelData.ssid + " (Signal: " + item.modelData.signal + ", Security: " + item.modelData.security + ")");
                        }

                        Component.onCompleted: {
                            // Ensure menu appears above other elements
                            menu.z = 100;
                        }

                        Variants {
                            id: ssidList

                            model: ssidSelector.ssids

                            MenuItem {
                                required property var modelData

                                text: modelData.ssid + (modelData.signal ? " (" + modelData.signal + "%)" : "")
                                icon: "wifi"
                            }
                        }

                        property list<var> ssids: []

                        function scanForSSIDs(): void {
                            appendLog("Scanning for wireless networks...");
                            // Use first wireless interface if available, or let nmcli choose
                            let iface = "";
                            if (interfaceSelector.selectedInterface) {
                                // Check if selected interface is wireless
                                for (const i of interfaceSelector.interfaces) {
                                    if (i.device === interfaceSelector.selectedInterface && i.type === "wifi") {
                                        iface = interfaceSelector.selectedInterface;
                                        break;
                                    }
                                }
                            }
                            
                            // If no wireless interface selected, use first available
                            if (!iface && Nmcli.wirelessInterfaces.length > 0) {
                                iface = Nmcli.wirelessInterfaces[0].device;
                            }
                            
                            Nmcli.scanWirelessNetworks(iface, (scanResult) => {
                                if (scanResult.success) {
                                    appendLog("Scan completed, fetching SSID list...");
                                    // Wait a moment for scan results to be available
                                    Qt.callLater(() => {
                                        Nmcli.getWirelessSSIDs(iface, (ssids) => {
                                            ssidSelector.ssids = ssids;
                                            if (ssids.length > 0) {
                                                Qt.callLater(() => {
                                                    if (ssidList.instances.length > 0) {
                                                        ssidSelector.active = ssidList.instances[0];
                                                        ssidSelector.selectedSSID = ssids[0].ssid;
                                                    }
                                                });
                                                appendLog("Found " + ssids.length + " SSIDs");
                                            } else {
                                                appendLog("No SSIDs found");
                                            }
                                        });
                                    }, 1000);
                                } else {
                                    appendLog("Scan failed: " + (scanResult.error || "Unknown error"));
                                }
                            });
                        }
                    }

                    TextButton {
                        text: qsTr("Scan")
                        onClicked: {
                            ssidSelector.scanForSSIDs();
                        }
                    }
                }
                }
            }
        }

        // Wireless Connection Test Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: connectionTestLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: connectionTestLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Wireless Connection Test")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("SSID: %1").arg(ssidSelector.selectedSSID || "None selected")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Connect (No Password)")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                appendLog("Connecting to: " + ssidSelector.selectedSSID + " (no password)");
                                // Find the network to get BSSID
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                const bssid = network ? network.bssid : "";
                                Nmcli.connectWireless(ssidSelector.selectedSSID, "", bssid, (result) => {
                                    if (result.success) {
                                        appendLog("Connection succeeded!");
                                        // Refresh network list after connection
                                        Qt.callLater(() => {
                                            Nmcli.getNetworks(() => {});
                                        }, 1000);
                                    } else {
                                        appendLog("Connection failed: " + (result.error || "Unknown error"));
                                        // Refresh network list anyway to check status
                                        Qt.callLater(() => {
                                            Nmcli.getNetworks(() => {});
                                        }, 1000);
                                    }
                                });
                                appendLog("Connection initiated, tracking pending connection...");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Password:")
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: passwordField.implicitHeight + Appearance.padding.small * 2

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
                            placeholderText: qsTr("Enter password")

                            Keys.onReturnPressed: {
                                if (connectWithPasswordButton.enabled) {
                                    connectWithPasswordButton.clicked();
                                }
                            }
                            Keys.onEnterPressed: {
                                if (connectWithPasswordButton.enabled) {
                                    connectWithPasswordButton.clicked();
                                }
                            }
                        }
                    }

                    TextButton {
                        id: connectWithPasswordButton
                        text: qsTr("Connect")
                        enabled: ssidSelector.selectedSSID.length > 0 && passwordField.text.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID && passwordField.text) {
                                appendLog("Connecting to: " + ssidSelector.selectedSSID + " (with password)");
                                // Find the network to get BSSID
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                const bssid = network ? network.bssid : "";
                                Nmcli.connectWireless(ssidSelector.selectedSSID, passwordField.text, bssid, (result) => {
                                    if (result.success) {
                                        appendLog("Connection succeeded!");
                                        // Clear password field
                                        passwordField.text = "";
                                        // Refresh network list after connection
                                        Qt.callLater(() => {
                                            Nmcli.getNetworks(() => {});
                                        }, 1000);
                                    } else {
                                        appendLog("Connection failed: " + (result.error || "Unknown error"));
                                        if (result.exitCode !== 0) {
                                            appendLog("Exit code: " + result.exitCode);
                                        }
                                        // Refresh network list anyway to check status
                                        Qt.callLater(() => {
                                            Nmcli.getNetworks(() => {});
                                        }, 1000);
                                    }
                                });
                                appendLog("Connection initiated, tracking pending connection...");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: {
                            const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                            const bssid = network && network.bssid ? network.bssid : "N/A";
                            return qsTr("BSSID: %1").arg(bssid);
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Saved Connection Profiles Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: savedProfilesLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: savedProfilesLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Saved Connection Profiles")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Connections: %1").arg(Nmcli.savedConnections.length)
                    }

                    StyledText {
                        text: qsTr("WiFi SSIDs: %1").arg(Nmcli.savedConnectionSsids.length)
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh")
                        onClicked: {
                            appendLog("Refreshing saved connections...");
                            Nmcli.loadSavedConnections((ssids) => {
                                appendLog("Found " + Nmcli.savedConnections.length + " saved connections");
                                appendLog("Found " + Nmcli.savedConnectionSsids.length + " WiFi SSIDs");
                            });
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Selected SSID: %1").arg(ssidSelector.selectedSSID || "None")
                    }

                    StyledText {
                        visible: ssidSelector.selectedSSID.length > 0
                        text: {
                            if (!ssidSelector.selectedSSID) return "";
                            const hasProfile = Nmcli.hasSavedProfile(ssidSelector.selectedSSID);
                            return hasProfile ? qsTr("[Saved Profile]") : qsTr("[Not Saved]");
                        }
                        color: {
                            if (!ssidSelector.selectedSSID) return Colours.palette.m3onSurface;
                            const hasProfile = Nmcli.hasSavedProfile(ssidSelector.selectedSSID);
                            return hasProfile ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant;
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Check Profile")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                const hasProfile = Nmcli.hasSavedProfile(ssidSelector.selectedSSID);
                                appendLog("Profile check for '" + ssidSelector.selectedSSID + "': " + (hasProfile ? "Saved" : "Not saved"));
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Forget Network")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                appendLog("Forgetting network: " + ssidSelector.selectedSSID);
                                Nmcli.forgetNetwork(ssidSelector.selectedSSID, (result) => {
                                    if (result.success) {
                                        appendLog("Network forgotten successfully");
                                    } else {
                                        appendLog("Failed to forget network: " + (result.error || "Unknown error"));
                                    }
                                });
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    TextButton {
                        text: qsTr("List All Saved SSIDs")
                        onClicked: {
                            appendLog("Saved WiFi SSIDs:");
                            if (Nmcli.savedConnectionSsids.length === 0) {
                                appendLog("  No saved SSIDs");
                            } else {
                                for (let i = 0; i < Nmcli.savedConnectionSsids.length; i++) {
                                    appendLog("  " + (i + 1) + ". " + Nmcli.savedConnectionSsids[i]);
                                }
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("List All Connections")
                        onClicked: {
                            appendLog("Saved Connections:");
                            if (Nmcli.savedConnections.length === 0) {
                                appendLog("  No saved connections");
                            } else {
                                for (let i = 0; i < Nmcli.savedConnections.length; i++) {
                                    appendLog("  " + (i + 1) + ". " + Nmcli.savedConnections[i]);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Pending Connection Tracking Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: pendingConnectionLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: pendingConnectionLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Pending Connection Tracking")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Status: %1").arg(Nmcli.pendingConnection ? "Connecting..." : "No pending connection")
                        color: Nmcli.pendingConnection ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        visible: Nmcli.pendingConnection
                        text: qsTr("SSID: %1").arg(Nmcli.pendingConnection ? Nmcli.pendingConnection.ssid : "")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Check Status")
                        onClicked: {
                            if (Nmcli.pendingConnection) {
                                appendLog("Pending connection: " + Nmcli.pendingConnection.ssid);
                                appendLog("BSSID: " + (Nmcli.pendingConnection.bssid || "N/A"));
                                const connected = Nmcli.active && Nmcli.active.ssid === Nmcli.pendingConnection.ssid;
                                appendLog("Connected: " + (connected ? "Yes" : "No"));
                                if (connected) {
                                    appendLog("Connection succeeded!");
                                } else {
                                    appendLog("Still connecting...");
                                }
                            } else {
                                appendLog("No pending connection");
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Clear Pending")
                        enabled: Nmcli.pendingConnection !== null
                        onClicked: {
                            if (Nmcli.pendingConnection) {
                                appendLog("Clearing pending connection: " + Nmcli.pendingConnection.ssid);
                                Nmcli.pendingConnection = null;
                                appendLog("Pending connection cleared");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Active Network: %1").arg(Nmcli.active ? Nmcli.active.ssid : "None")
                        color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh Networks & Check")
                        onClicked: {
                            appendLog("Refreshing network list to check pending connection...");
                            Nmcli.getNetworks((networks) => {
                                appendLog("Network list refreshed");
                                if (Nmcli.pendingConnection) {
                                    const connected = Nmcli.active && Nmcli.active.ssid === Nmcli.pendingConnection.ssid;
                                    appendLog("Pending connection check: " + (connected ? "Connected!" : "Still connecting..."));
                                }
                            });
                        }
                    }
                }
            }
        }

        // Connection Failure Handling Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: connectionFailureLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: connectionFailureLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Connection Failure Handling")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Last Failed SSID: %1").arg(lastFailedSsid || "None")
                        color: lastFailedSsid ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Clear Failure")
                        enabled: lastFailedSsid.length > 0
                        onClicked: {
                            lastFailedSsid = "";
                            appendLog("Cleared failure status");
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Test Password Detection")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Secure Network (No Password)")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                if (network && network.isSecure) {
                                    appendLog("Testing connection to secure network without password (should detect password requirement)");
                                    const bssid = network ? network.bssid : "";
                                    Nmcli.connectWireless(ssidSelector.selectedSSID, "", bssid, (result) => {
                                        if (result.needsPassword) {
                                            appendLog("✓ Password requirement detected correctly!");
                                            appendLog("Error: " + (result.error || "N/A"));
                                        } else if (result.success) {
                                            appendLog("Connection succeeded (saved password used)");
                                        } else {
                                            appendLog("Connection failed: " + (result.error || "Unknown error"));
                                        }
                                    });
                                } else {
                                    appendLog("Selected network is not secure, cannot test password detection");
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Connection Retry Test")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Retry Logic")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                appendLog("Testing connection retry logic (will retry up to 2 times on failure)");
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                const bssid = network ? network.bssid : "";
                                // Use invalid password to trigger failure
                                Nmcli.connectWireless(ssidSelector.selectedSSID, "invalid_password_test", bssid, (result) => {
                                    if (result.success) {
                                        appendLog("Connection succeeded (unexpected)");
                                    } else {
                                        appendLog("Connection failed after retries: " + (result.error || "Unknown error"));
                                    }
                                });
                            }
                        }
                    }
                }
            }
        }

        // Password Callback Handling Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: passwordCallbackLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: passwordCallbackLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Password Callback Handling")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Selected SSID: %1").arg(ssidSelector.selectedSSID || "None")
                    }

                    StyledText {
                        visible: ssidSelector.selectedSSID.length > 0
                        text: {
                            if (!ssidSelector.selectedSSID) return "";
                            const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                            if (!network) return "";
                            return network.isSecure ? qsTr("[Secure]") : qsTr("[Open]");
                        }
                        color: {
                            if (!ssidSelector.selectedSSID) return Colours.palette.m3onSurface;
                            const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                            if (!network) return Colours.palette.m3onSurface;
                            return network.isSecure ? Colours.palette.m3error : Colours.palette.m3primary;
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Password Check (Secure)")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                if (network && network.isSecure) {
                                    appendLog("Testing password check for secure network: " + ssidSelector.selectedSSID);
                                    appendLog("This will try saved password first, then prompt if needed");
                                    const bssid = network ? network.bssid : "";
                                    Nmcli.connectToNetworkWithPasswordCheck(ssidSelector.selectedSSID, true, (result) => {
                                        if (result.success) {
                                            if (result.usedSavedPassword) {
                                                appendLog("✓ Connection succeeded using saved password!");
                                            } else {
                                                appendLog("✓ Connection succeeded!");
                                            }
                                            // Refresh network list
                                            Qt.callLater(() => {
                                                Nmcli.getNetworks(() => {});
                                            }, 1000);
                                        } else if (result.needsPassword) {
                                            appendLog("→ Password required - callback triggered");
                                            appendLog("  Error: " + (result.error || "N/A"));
                                            appendLog("  (In real UI, this would show password dialog)");
                                        } else {
                                            appendLog("✗ Connection failed: " + (result.error || "Unknown error"));
                                        }
                                    }, bssid);
                                } else {
                                    appendLog("Selected network is not secure, cannot test password check");
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Test Open Network")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Password Check (Open)")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                if (network && !network.isSecure) {
                                    appendLog("Testing password check for open network: " + ssidSelector.selectedSSID);
                                    appendLog("Open networks should connect directly without password");
                                    const bssid = network ? network.bssid : "";
                                    Nmcli.connectToNetworkWithPasswordCheck(ssidSelector.selectedSSID, false, (result) => {
                                        if (result.success) {
                                            appendLog("✓ Connection succeeded!");
                                            // Refresh network list
                                            Qt.callLater(() => {
                                                Nmcli.getNetworks(() => {});
                                            }, 1000);
                                        } else {
                                            appendLog("✗ Connection failed: " + (result.error || "Unknown error"));
                                        }
                                    }, bssid);
                                } else {
                                    appendLog("Selected network is not open, cannot test open network handling");
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Test with Saved Password")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Secure Network (Has Saved Password)")
                        enabled: ssidSelector.selectedSSID.length > 0
                        onClicked: {
                            if (ssidSelector.selectedSSID) {
                                const network = Nmcli.networks.find(n => n.ssid === ssidSelector.selectedSSID);
                                if (network && network.isSecure) {
                                    const hasSaved = Nmcli.hasSavedProfile(ssidSelector.selectedSSID);
                                    appendLog("Testing password check for: " + ssidSelector.selectedSSID);
                                    appendLog("Has saved profile: " + (hasSaved ? "Yes" : "No"));
                                    if (hasSaved) {
                                        appendLog("This should connect using saved password without prompting");
                                    } else {
                                        appendLog("This should prompt for password since no saved profile exists");
                                    }
                                    const bssid = network ? network.bssid : "";
                                    Nmcli.connectToNetworkWithPasswordCheck(ssidSelector.selectedSSID, true, (result) => {
                                        if (result.success) {
                                            if (result.usedSavedPassword) {
                                                appendLog("✓ Connection succeeded using saved password!");
                                            } else {
                                                appendLog("✓ Connection succeeded!");
                                            }
                                            // Refresh network list
                                            Qt.callLater(() => {
                                                Nmcli.getNetworks(() => {});
                                            }, 1000);
                                        } else if (result.needsPassword) {
                                            appendLog("→ Password required - callback triggered");
                                            appendLog("  (In real UI, this would show password dialog)");
                                        } else {
                                            appendLog("✗ Connection failed: " + (result.error || "Unknown error"));
                                        }
                                    }, bssid);
                                } else {
                                    appendLog("Selected network is not secure, cannot test saved password");
                                }
                            }
                        }
                    }
                }
            }
        }

        // Device Details Parsing Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: deviceDetailsLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: deviceDetailsLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Device Details Parsing")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Wireless Device Details")
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Get Wireless Details")
                        onClicked: {
                            const activeInterface = interfaceSelector.selectedInterface;
                            if (activeInterface && activeInterface.length > 0) {
                                appendLog("Getting wireless device details for: " + activeInterface);
                                Nmcli.getWirelessDeviceDetails(activeInterface, (details) => {
                                    if (details) {
                                        appendLog("Wireless Device Details:");
                                        appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                        appendLog("  Gateway: " + (details.gateway || "N/A"));
                                        appendLog("  Subnet: " + (details.subnet || "N/A"));
                                        appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                        appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                                    } else {
                                        appendLog("Failed to get wireless device details");
                                    }
                                });
                            } else {
                                appendLog("Getting wireless device details for active interface");
                                Nmcli.getWirelessDeviceDetails("", (details) => {
                                    if (details) {
                                        appendLog("Wireless Device Details:");
                                        appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                        appendLog("  Gateway: " + (details.gateway || "N/A"));
                                        appendLog("  Subnet: " + (details.subnet || "N/A"));
                                        appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                        appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                                    } else {
                                        appendLog("No active wireless interface or failed to get details");
                                    }
                                });
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Show Current")
                        onClicked: {
                            if (Nmcli.wirelessDeviceDetails) {
                                const details = Nmcli.wirelessDeviceDetails;
                                appendLog("Current Wireless Device Details:");
                                appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                appendLog("  Gateway: " + (details.gateway || "N/A"));
                                appendLog("  Subnet: " + (details.subnet || "N/A"));
                                appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                            } else {
                                appendLog("No wireless device details available");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Ethernet Device Details")
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Get Ethernet Details")
                        onClicked: {
                            const activeInterface = interfaceSelector.selectedInterface;
                            if (activeInterface && activeInterface.length > 0) {
                                appendLog("Getting ethernet device details for: " + activeInterface);
                                Nmcli.getEthernetDeviceDetails(activeInterface, (details) => {
                                    if (details) {
                                        appendLog("Ethernet Device Details:");
                                        appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                        appendLog("  Gateway: " + (details.gateway || "N/A"));
                                        appendLog("  Subnet: " + (details.subnet || "N/A"));
                                        appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                        appendLog("  Speed: " + (details.speed || "N/A"));
                                        appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                                    } else {
                                        appendLog("Failed to get ethernet device details");
                                    }
                                });
                            } else {
                                appendLog("Getting ethernet device details for active interface");
                                Nmcli.getEthernetDeviceDetails("", (details) => {
                                    if (details) {
                                        appendLog("Ethernet Device Details:");
                                        appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                        appendLog("  Gateway: " + (details.gateway || "N/A"));
                                        appendLog("  Subnet: " + (details.subnet || "N/A"));
                                        appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                        appendLog("  Speed: " + (details.speed || "N/A"));
                                        appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                                    } else {
                                        appendLog("No active ethernet interface or failed to get details");
                                    }
                                });
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Show Current")
                        onClicked: {
                            if (Nmcli.ethernetDeviceDetails) {
                                const details = Nmcli.ethernetDeviceDetails;
                                appendLog("Current Ethernet Device Details:");
                                appendLog("  IP Address: " + (details.ipAddress || "N/A"));
                                appendLog("  Gateway: " + (details.gateway || "N/A"));
                                appendLog("  Subnet: " + (details.subnet || "N/A"));
                                appendLog("  MAC Address: " + (details.macAddress || "N/A"));
                                appendLog("  Speed: " + (details.speed || "N/A"));
                                appendLog("  DNS: " + (details.dns && details.dns.length > 0 ? details.dns.join(", ") : "N/A"));
                            } else {
                                appendLog("No ethernet device details available");
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("CIDR to Subnet Mask Test")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test CIDR Conversion")
                        onClicked: {
                            appendLog("Testing CIDR to Subnet Mask conversion:");
                            const testCases = ["8", "16", "24", "32", "0", "25", "30"];
                            for (let i = 0; i < testCases.length; i++) {
                                const cidr = testCases[i];
                                const subnet = Nmcli.cidrToSubnetMask(cidr);
                                appendLog("  /" + cidr + " -> " + (subnet || "Invalid"));
                            }
                        }
                    }
                }
            }
        }

        // Connection Status Monitoring Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: connectionMonitoringLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: connectionMonitoringLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Connection Status Monitoring")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Active Network: %1").arg(Nmcli.active ? Nmcli.active.ssid : "None")
                        color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        visible: Nmcli.active
                        text: Nmcli.active ? qsTr("Signal: %1%").arg(Nmcli.active.strength) : ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh Networks")
                        onClicked: {
                            appendLog("Manually refreshing network list...");
                            Nmcli.getNetworks((networks) => {
                                appendLog("Network list refreshed: " + networks.length + " networks");
                                if (Nmcli.active) {
                                    appendLog("Active network: " + Nmcli.active.ssid);
                                } else {
                                    appendLog("No active network");
                                }
                            });
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Monitor Status")
                    }

                    StyledText {
                        text: qsTr("Monitoring connection changes (automatic refresh enabled)")
                        color: Colours.palette.m3primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Test Connection Change")
                        onClicked: {
                            appendLog("Testing connection change detection...");
                            appendLog("This will trigger a manual refresh to simulate a connection change");
                            Nmcli.refreshOnConnectionChange();
                            appendLog("Refresh triggered - check if network list and device details updated");
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Device Details Auto-Refresh")
                    }

                    StyledText {
                        text: {
                            if (Nmcli.wirelessDeviceDetails) {
                                return qsTr("Wireless: %1").arg(Nmcli.wirelessDeviceDetails.ipAddress || "N/A");
                            } else if (Nmcli.ethernetDeviceDetails) {
                                return qsTr("Ethernet: %1").arg(Nmcli.ethernetDeviceDetails.ipAddress || "N/A");
                            } else {
                                return qsTr("No device details");
                            }
                        }
                        color: (Nmcli.wirelessDeviceDetails || Nmcli.ethernetDeviceDetails) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh Device Details")
                        onClicked: {
                            appendLog("Manually refreshing device details...");
                            if (Nmcli.active && Nmcli.active.active) {
                                appendLog("Active network detected, refreshing device details...");
                                // Refresh wireless device details
                                if (Nmcli.wirelessInterfaces.length > 0) {
                                    const activeWireless = Nmcli.wirelessInterfaces.find(iface => {
                                        return iface.state === "connected" || iface.state.startsWith("connected");
                                    });
                                    if (activeWireless && activeWireless.device) {
                                        Nmcli.getWirelessDeviceDetails(activeWireless.device, (details) => {
                                            if (details) {
                                                appendLog("Wireless device details refreshed");
                                            }
                                        });
                                    }
                                }
                                // Refresh ethernet device details
                                if (Nmcli.ethernetInterfaces.length > 0) {
                                    const activeEthernet = Nmcli.ethernetInterfaces.find(iface => {
                                        return iface.state === "connected" || iface.state.startsWith("connected");
                                    });
                                    if (activeEthernet && activeEthernet.device) {
                                        Nmcli.getEthernetDeviceDetails(activeEthernet.device, (details) => {
                                            if (details) {
                                                appendLog("Ethernet device details refreshed");
                                            }
                                        });
                                    }
                                }
                            } else {
                                appendLog("No active network, clearing device details");
                                Nmcli.wirelessDeviceDetails = null;
                                Nmcli.ethernetDeviceDetails = null;
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Connection Events")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Show Active Network Info")
                        onClicked: {
                            if (Nmcli.active) {
                                appendLog("Active Network Information:");
                                appendLog("  SSID: " + Nmcli.active.ssid);
                                appendLog("  BSSID: " + (Nmcli.active.bssid || "N/A"));
                                appendLog("  Signal: " + Nmcli.active.strength + "%");
                                appendLog("  Frequency: " + Nmcli.active.frequency + " MHz");
                                appendLog("  Security: " + (Nmcli.active.security || "Open"));
                                appendLog("  Is Secure: " + (Nmcli.active.isSecure ? "Yes" : "No"));
                            } else {
                                appendLog("No active network");
                            }
                        }
                    }
                }
            }
        }

        // Ethernet Device Management Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: ethernetManagementLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: ethernetManagementLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Ethernet Device Management")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Ethernet Devices: %1").arg(Nmcli.ethernetDevices.length)
                    }

                    StyledText {
                        text: qsTr("Active: %1").arg(Nmcli.activeEthernet ? Nmcli.activeEthernet.interface : "None")
                        color: Nmcli.activeEthernet ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Refresh Devices")
                        onClicked: {
                            appendLog("Refreshing ethernet devices...");
                            Nmcli.getEthernetInterfaces((interfaces) => {
                                appendLog("Found " + Nmcli.ethernetDevices.length + " ethernet devices");
                                for (let i = 0; i < Nmcli.ethernetDevices.length; i++) {
                                    const dev = Nmcli.ethernetDevices[i];
                                    appendLog("  " + (i + 1) + ". " + dev.interface + " - " + dev.state + (dev.connected ? " [Connected]" : ""));
                                }
                                if (Nmcli.activeEthernet) {
                                    appendLog("Active ethernet: " + Nmcli.activeEthernet.interface);
                                }
                            });
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Selected Interface: %1").arg(interfaceSelector.selectedInterface || "None")
                    }

                    StyledText {
                        visible: interfaceSelector.selectedInterface.length > 0
                        text: {
                            if (!interfaceSelector.selectedInterface) return "";
                            const device = Nmcli.ethernetDevices.find(d => d.interface === interfaceSelector.selectedInterface);
                            if (!device) return "";
                            return device.connected ? qsTr("[Connected]") : qsTr("[Disconnected]");
                        }
                        color: {
                            if (!interfaceSelector.selectedInterface) return Colours.palette.m3onSurface;
                            const device = Nmcli.ethernetDevices.find(d => d.interface === interfaceSelector.selectedInterface);
                            if (!device) return Colours.palette.m3onSurface;
                            return device.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant;
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Connect Ethernet")
                        enabled: interfaceSelector.selectedInterface.length > 0
                        onClicked: {
                            if (interfaceSelector.selectedInterface) {
                                const device = Nmcli.ethernetDevices.find(d => d.interface === interfaceSelector.selectedInterface);
                                if (device) {
                                    appendLog("Connecting ethernet: " + interfaceSelector.selectedInterface);
                                    appendLog("Connection name: " + (device.connection || "N/A"));
                                    Nmcli.connectEthernet(device.connection || "", interfaceSelector.selectedInterface, (result) => {
                                        if (result.success) {
                                            appendLog("✓ Ethernet connection initiated");
                                            appendLog("Refreshing device list...");
                                        } else {
                                            appendLog("✗ Failed to connect: " + (result.error || "Unknown error"));
                                        }
                                    });
                                } else {
                                    appendLog("Device not found in ethernet devices list");
                                }
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Disconnect Ethernet")
                        enabled: interfaceSelector.selectedInterface.length > 0
                        onClicked: {
                            if (interfaceSelector.selectedInterface) {
                                const device = Nmcli.ethernetDevices.find(d => d.interface === interfaceSelector.selectedInterface);
                                if (device && device.connection) {
                                    appendLog("Disconnecting ethernet: " + device.connection);
                                    Nmcli.disconnectEthernet(device.connection, (result) => {
                                        if (result.success) {
                                            appendLog("✓ Ethernet disconnected");
                                            appendLog("Refreshing device list...");
                                        } else {
                                            appendLog("✗ Failed to disconnect: " + (result.error || "Unknown error"));
                                        }
                                    });
                                } else {
                                    appendLog("No connection name available for this device");
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("List All Ethernet Devices")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("List Devices")
                        onClicked: {
                            appendLog("Ethernet Devices:");
                            if (Nmcli.ethernetDevices.length === 0) {
                                appendLog("  No ethernet devices found");
                            } else {
                                for (let i = 0; i < Nmcli.ethernetDevices.length; i++) {
                                    const dev = Nmcli.ethernetDevices[i];
                                    appendLog("  " + (i + 1) + ". " + dev.interface);
                                    appendLog("      Type: " + dev.type);
                                    appendLog("      State: " + dev.state);
                                    appendLog("      Connection: " + (dev.connection || "None"));
                                    appendLog("      Connected: " + (dev.connected ? "Yes" : "No"));
                                }
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Show Active Device")
                        onClicked: {
                            if (Nmcli.activeEthernet) {
                                appendLog("Active Ethernet Device:");
                                appendLog("  Interface: " + Nmcli.activeEthernet.interface);
                                appendLog("  State: " + Nmcli.activeEthernet.state);
                                appendLog("  Connection: " + (Nmcli.activeEthernet.connection || "None"));
                            } else {
                                appendLog("No active ethernet device");
                            }
                        }
                    }
                }
            }
        }

        // Debug Output Section
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            Layout.minimumHeight: 200
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Debug Output")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Copy")
                        onClicked: {
                            debugOutput.selectAll();
                            debugOutput.copy();
                            debugOutput.deselect();
                            appendLog("Output copied to clipboard");
                        }
                    }
                }

                StyledFlickable {
                    id: debugOutputFlickable

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    flickableDirection: Flickable.VerticalFlick
                    clip: true

                    TextEdit {
                        id: debugOutput

                        width: debugOutputFlickable.width
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        font.family: Appearance.font.family.mono
                        font.pointSize: Appearance.font.size.smaller
                        renderType: TextEdit.NativeRendering
                        textFormat: TextEdit.PlainText
                        color: "#ffb0ca"  // Use primary color - will be set programmatically
                        
                        Component.onCompleted: {
                            color = Colours.palette.m3primary;
                            appendLog("Debug panel initialized");
                        }

                        onTextChanged: {
                            // Ensure color stays set when text changes
                            color = Colours.palette.m3primary;
                            // Update content height
                            debugOutputFlickable.contentHeight = Math.max(implicitHeight, debugOutputFlickable.height);
                            // Auto-scroll to bottom
                            Qt.callLater(() => {
                                if (debugOutputFlickable.contentHeight > debugOutputFlickable.height) {
                                    debugOutputFlickable.contentY = debugOutputFlickable.contentHeight - debugOutputFlickable.height;
                                }
                            });
                        }
                    }
                }

                StyledScrollBar {
                    flickable: debugOutputFlickable
                    policy: ScrollBar.AlwaysOn
                }
            }
        }
        }
    }

    function appendLog(message: string): void {
        const timestamp = new Date().toLocaleTimeString();
        debugOutput.text += `[${timestamp}] ${message}\n`;
    }

    function log(message: string): void {
        appendLog(message);
    }

    Component.onCompleted: {
        // Set up debug logger for Nmcli service
        Nmcli.setDebugLogger((msg) => {
            appendLog("[Nmcli] " + msg);
        });
    }
}

