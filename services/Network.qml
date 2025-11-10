pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    Component.onCompleted: {
        // Trigger ethernet device detection after initialization
        Qt.callLater(() => {
            getEthernetDevices();
        });
    }

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

    property list<var> ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    property int ethernetDeviceCount: 0
    property string ethernetDebugInfo: ""
    property bool ethernetProcessRunning: false
    property var ethernetDeviceDetails: null

    function enableWifi(enabled: bool): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    property var pendingConnection: null
    signal connectionFailed(string ssid)

    function connectToNetwork(ssid: string, password: string): void {
        // First try to connect to an existing connection
        // If that fails, create a new connection
        if (password && password.length > 0) {
            connectProc.exec(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
        } else {
            // Try to connect to existing connection first (will use saved password if available)
            connectProc.exec(["nmcli", "device", "wifi", "connect", ssid]);
        }
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var): void {
        // For secure networks, try connecting without password first
        // If connection succeeds (saved password exists), we're done
        // If it fails with password error, callback will be called to show password dialog
        if (isSecure) {
            root.pendingConnection = { ssid: ssid, callback: callback };
            // Try connecting without password - will use saved password if available
            connectProc.exec(["nmcli", "device", "wifi", "connect", ssid]);
            // Start timer to check if connection succeeded
            connectionCheckTimer.start();
        } else {
            connectToNetwork(ssid, "");
        }
    }

    function disconnectFromNetwork(): void {
        // Try to disconnect - use connection name if available, otherwise use device
        if (active && active.ssid) {
            // First try to disconnect by connection name (more reliable)
            disconnectByConnectionProc.exec(["nmcli", "connection", "down", active.ssid]);
        } else {
            // Fallback: disconnect by device
            disconnectProc.exec(["nmcli", "device", "disconnect", "wifi"]);
        }
    }

    function getWifiStatus(): void {
        wifiStatusProc.running = true;
    }

    function getEthernetDevices(): void {
        getEthernetDevicesProc.running = true;
    }


    function connectEthernet(connectionName: string, interfaceName: string): void {
        if (connectionName && connectionName.length > 0) {
            // Use connection name if available
            connectEthernetProc.exec(["nmcli", "connection", "up", connectionName]);
        } else if (interfaceName && interfaceName.length > 0) {
            // Fallback to device interface if no connection name
            connectEthernetProc.exec(["nmcli", "device", "connect", interfaceName]);
        }
    }

    function disconnectEthernet(connectionName: string): void {
        disconnectEthernetProc.exec(["nmcli", "connection", "down", connectionName]);
    }

    function updateEthernetDeviceDetails(interfaceName: string): void {
        if (interfaceName && interfaceName.length > 0) {
            getEthernetDetailsProc.exec(["nmcli", "device", "show", interfaceName]);
        } else {
            ethernetDeviceDetails = null;
        }
    }

    function cidrToSubnetMask(cidr: string): string {
        // Convert CIDR notation (e.g., "24") to subnet mask (e.g., "255.255.255.0")
        const cidrNum = parseInt(cidr);
        if (isNaN(cidrNum) || cidrNum < 0 || cidrNum > 32) {
            return "";
        }
        
        const mask = (0xffffffff << (32 - cidrNum)) >>> 0;
        const octets = [
            (mask >>> 24) & 0xff,
            (mask >>> 16) & 0xff,
            (mask >>> 8) & 0xff,
            mask & 0xff
        ];
        
        return octets.join(".");
    }

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: {
                getNetworks.running = true;
                getEthernetDevices();
            }
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            getNetworks.running = true;
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getNetworks.running = true;
        }
    }

    Timer {
        id: connectionCheckTimer
        interval: 4000
        onTriggered: {
            if (root.pendingConnection) {
                // Final check - if connection still hasn't succeeded, show password dialog
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                if (!connected && root.pendingConnection.callback) {
                    // Connection didn't succeed after multiple checks, show password dialog
                    const pending = root.pendingConnection;
                    root.pendingConnection = null;
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    pending.callback();
                } else if (connected) {
                    // Connection succeeded, clear pending
                    root.pendingConnection = null;
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                }
            }
        }
    }

    Timer {
        id: immediateCheckTimer
        interval: 500
        repeat: true
        triggeredOnStart: false
        property int checkCount: 0
        onTriggered: {
            if (root.pendingConnection) {
                checkCount++;
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                if (connected) {
                    // Connection succeeded, stop timers and clear pending
                    connectionCheckTimer.stop();
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    root.pendingConnection = null;
                } else if (checkCount >= 6) {
                    // Checked 6 times (3 seconds total), connection likely failed
                    // Stop immediate check, let the main timer handle it
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                }
            } else {
                immediateCheckTimer.stop();
                immediateCheckTimer.checkCount = 0;
            }
        }
    }

    Process {
        id: connectProc

        onExited: {
            // Refresh network list after connection attempt
            getNetworks.running = true;
            
            // Check if connection succeeded after a short delay (network list needs to update)
            if (root.pendingConnection) {
                immediateCheckTimer.start();
            }
        }
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0) {
                    // Check for specific errors that indicate password is needed
                    // Be careful not to match success messages
                    const needsPassword = (error.includes("Secrets were required") || 
                                        error.includes("No secrets provided") ||
                                        error.includes("802-11-wireless-security.psk") ||
                                        (error.includes("password") && !error.includes("Connection activated")) ||
                                        (error.includes("Secrets") && !error.includes("Connection activated")) ||
                                        (error.includes("802.11") && !error.includes("Connection activated"))) &&
                                        !error.includes("Connection activated") &&
                                        !error.includes("successfully");
                    
                    if (needsPassword && root.pendingConnection && root.pendingConnection.callback) {
                        // Connection failed because password is needed - show dialog immediately
                        connectionCheckTimer.stop();
                        immediateCheckTimer.stop();
                        const pending = root.pendingConnection;
                        root.pendingConnection = null;
                        pending.callback();
                    } else if (error && error.length > 0 && !error.includes("Connection activated")) {
                        // Only log non-success messages
                        console.warn("Network connection error:", error);
                    }
                }
            }
        }
    }

    Process {
        id: disconnectProc

        onExited: {
            // Refresh network list after disconnection
            getNetworks.running = true;
        }
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0 && !error.includes("successfully") && !error.includes("disconnected")) {
                    console.warn("Network device disconnect error:", error);
                }
            }
        }
    }

    Process {
        id: disconnectByConnectionProc

        onExited: {
            // Refresh network list after disconnection
            getNetworks.running = true;
        }
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0 && !error.includes("successfully") && !error.includes("disconnected")) {
                    console.warn("Network connection disconnect error:", error);
                    // If connection down failed, try device disconnect as fallback
                    disconnectProc.exec(["nmcli", "device", "disconnect", "wifi"]);
                }
            }
        }
    }

    Process {
        id: getNetworks

        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }

                // Check if pending connection succeeded after network list is fully updated
                if (root.pendingConnection) {
                    Qt.callLater(() => {
                        const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                        if (connected) {
                            // Connection succeeded, stop timers and clear pending
                            connectionCheckTimer.stop();
                            immediateCheckTimer.stop();
                            immediateCheckTimer.checkCount = 0;
                            root.pendingConnection = null;
                        }
                    });
                }
            }
        }
    }

    Process {
        id: getEthernetDevicesProc

        running: false
        command: ["nmcli", "-g", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        onRunningChanged: {
            root.ethernetProcessRunning = running;
            if (!running) {
                // Process finished, update debug info
                Qt.callLater(() => {
                    if (root.ethernetDebugInfo === "" || root.ethernetDebugInfo.includes("Process exited")) {
                        root.ethernetDebugInfo = "Process finished, waiting for output...";
                    }
                });
            }
        }
        onExited: {
            Qt.callLater(() => {
                const outputLength = ethernetStdout.text ? ethernetStdout.text.length : 0;
                root.ethernetDebugInfo = "Process exited with code: " + exitCode + ", output length: " + outputLength;
                if (outputLength > 0) {
                    // Output was captured, process it
                    const output = ethernetStdout.text.trim();
                    root.ethernetDebugInfo = "Processing output from onExited, length: " + output.length + "\nOutput: " + output.substring(0, 200);
                    root.processEthernetOutput(output);
                } else {
                    root.ethernetDebugInfo = "No output captured in onExited";
                }
            });
        }
        stdout: StdioCollector {
            id: ethernetStdout
            onStreamFinished: {
                const output = text.trim();
                root.ethernetDebugInfo = "Output received in onStreamFinished! Length: " + output.length + ", First 100 chars: " + output.substring(0, 100);
                
                if (!output || output.length === 0) {
                    root.ethernetDebugInfo = "No output received (empty)";
                    return;
                }
                
                root.processEthernetOutput(output);
            }
        }
    }

    function processEthernetOutput(output: string): void {
        const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
        const rep = new RegExp("\\\\:", "g");
        const rep2 = new RegExp(PLACEHOLDER, "g");

        const lines = output.split("\n");
        root.ethernetDebugInfo = "Processing " + lines.length + " lines";
        
        const allDevices = lines.map(d => {
            const dev = d.replace(rep, PLACEHOLDER).split(":");
            return {
                interface: dev[0]?.replace(rep2, ":") ?? "",
                type: dev[1]?.replace(rep2, ":") ?? "",
                state: dev[2]?.replace(rep2, ":") ?? "",
                connection: dev[3]?.replace(rep2, ":") ?? ""
            };
        });
        
        root.ethernetDebugInfo = "All devices: " + allDevices.length + ", Types: " + allDevices.map(d => d.type).join(", ");
        
        const ethernetOnly = allDevices.filter(d => d.type === "ethernet");
        root.ethernetDebugInfo = "Ethernet devices found: " + ethernetOnly.length;

        const ethernetDevices = ethernetOnly.map(d => {
            const state = d.state || "";
            const connected = state === "100 (connected)" || state === "connected" || state.startsWith("connected");
            return {
                interface: d.interface,
                type: d.type,
                state: state,
                connection: d.connection,
                connected: connected,
                ipAddress: "",
                gateway: "",
                dns: [],
                subnet: "",
                macAddress: "",
                speed: ""
            };
        });
        
        root.ethernetDebugInfo = "Ethernet devices processed: " + ethernetDevices.length + ", First device: " + (ethernetDevices[0]?.interface || "none");

        // Update the list - replace the entire array to ensure QML detects the change
        // Create a new array and assign it to the property
        const newDevices = [];
        for (let i = 0; i < ethernetDevices.length; i++) {
            newDevices.push(ethernetDevices[i]);
        }
        
        // Replace the entire list
        root.ethernetDevices = newDevices;
        
        // Force QML to detect the change by updating a property
        root.ethernetDeviceCount = ethernetDevices.length;
        
        // Force QML to re-evaluate the list by accessing it
        Qt.callLater(() => {
            const count = root.ethernetDevices.length;
            root.ethernetDebugInfo = "Final: Found " + ethernetDevices.length + " devices, List length: " + count + ", Parsed all: " + allDevices.length + ", Output length: " + output.length;
        });
    }


    Process {
        id: connectEthernetProc

        onExited: {
            getEthernetDevices();
            // Refresh device details after connection
            Qt.callLater(() => {
                const activeDevice = root.ethernetDevices.find(function(d) { return d.connected; });
                if (activeDevice && activeDevice.interface) {
                    updateEthernetDeviceDetails(activeDevice.interface);
                }
            });
        }
        stdout: SplitParser {
            onRead: getEthernetDevices()
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0 && !error.includes("successfully") && !error.includes("Connection activated")) {
                    console.warn("Ethernet connection error:", error);
                }
            }
        }
    }

    Process {
        id: disconnectEthernetProc

        onExited: {
            getEthernetDevices();
            // Clear device details after disconnection
            Qt.callLater(() => {
                root.ethernetDeviceDetails = null;
            });
        }
        stdout: SplitParser {
            onRead: getEthernetDevices()
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0 && !error.includes("successfully") && !error.includes("disconnected")) {
                    console.warn("Ethernet disconnection error:", error);
                }
            }
        }
    }

    Process {
        id: getEthernetDetailsProc

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output || output.length === 0) {
                    root.ethernetDeviceDetails = null;
                    return;
                }

                const lines = output.split("\n");
                const details = {
                    ipAddress: "",
                    gateway: "",
                    dns: [],
                    subnet: "",
                    macAddress: "",
                    speed: ""
                };

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    const parts = line.split(":");
                    if (parts.length >= 2) {
                        const key = parts[0].trim();
                        const value = parts.slice(1).join(":").trim();

                        if (key.startsWith("IP4.ADDRESS")) {
                            // Extract IP and subnet from format like "10.13.1.45/24"
                            const ipParts = value.split("/");
                            details.ipAddress = ipParts[0] || "";
                            if (ipParts[1]) {
                                // Convert CIDR notation to subnet mask
                                details.subnet = root.cidrToSubnetMask(ipParts[1]);
                            } else {
                                details.subnet = "";
                            }
                        } else if (key === "IP4.GATEWAY") {
                            details.gateway = value;
                        } else if (key.startsWith("IP4.DNS")) {
                            details.dns.push(value);
                        } else if (key === "WIRED-PROPERTIES.MAC") {
                            details.macAddress = value;
                        } else if (key === "WIRED-PROPERTIES.SPEED") {
                            details.speed = value;
                        }
                    }
                }

                root.ethernetDeviceDetails = details;
            }
        }
        onExited: {
            if (exitCode !== 0) {
                root.ethernetDeviceDetails = null;
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
