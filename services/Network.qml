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
        // Load saved connections on startup
        listConnectionsProc.running = true;
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
    property var wirelessDeviceDetails: null
    property string connectionStatus: ""
    property string connectionDebug: ""
    
    function clearConnectionStatus(): void {
        connectionStatus = "";
        // Don't clear debug - keep it for reference
        // connectionDebug = "";
    }
    
    function setConnectionStatus(status: string): void {
        connectionStatus = status;
    }
    
    function addDebugInfo(info: string): void {
        const timestamp = new Date().toLocaleTimeString();
        const newInfo = "[" + timestamp + "] " + info;
        // CRITICAL: Always append - NEVER replace
        // Get current value - NEVER allow it to be empty/cleared
        let current = connectionDebug;
        if (!current || current === undefined || current === null) {
            current = "";
        }
        // ALWAYS append - never replace
        // If current is empty, just use newInfo, otherwise append with newline
        const updated = (current.length > 0) ? (current + "\n" + newInfo) : newInfo;
        // CRITICAL: Only assign if we're appending, never replace
        connectionDebug = updated;
    }

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

    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        // When password is provided, use BSSID for more reliable connection
        // When no password, use SSID (will use saved password if available)
        const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
        let cmd = [];
        
        // Set up pending connection tracking if callback provided
        if (callback) {
            root.pendingConnection = { ssid: ssid, bssid: hasBssid ? bssid : "", callback: callback };
        }
        
        if (password && password.length > 0) {
            // When password is provided, try BSSID first if available, otherwise use SSID
            if (hasBssid) {
                // Use BSSID when password is provided - ensure BSSID is uppercase
                const bssidUpper = bssid.toUpperCase();
                // Create connection profile with all required properties for BSSID + password
                // First remove any existing connection with this name
                cmd = ["nmcli", "connection", "add", 
                       "type", "wifi", 
                       "con-name", ssid,
                       "ifname", "*",
                       "ssid", ssid,
                       "802-11-wireless.bssid", bssidUpper,
                       "802-11-wireless-security.key-mgmt", "wpa-psk",
                       "802-11-wireless-security.psk", password];
                root.setConnectionStatus(qsTr("Connecting to %1 (BSSID: %2)...").arg(ssid).arg(bssidUpper));
                root.addDebugInfo(qsTr("Using BSSID: %1 for SSID: %2").arg(bssidUpper).arg(ssid));
                root.addDebugInfo(qsTr("Creating connection profile with password and key-mgmt"));
            } else {
                // Fallback to SSID if BSSID not available - use device wifi connect
                cmd = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
                root.setConnectionStatus(qsTr("Connecting to %1...").arg(ssid));
                root.addDebugInfo(qsTr("Using SSID only (no BSSID): %1").arg(ssid));
            }
        } else {
            // Try to connect to existing connection first (will use saved password if available)
            cmd = ["nmcli", "device", "wifi", "connect", ssid];
            root.setConnectionStatus(qsTr("Connecting to %1 (using saved password)...").arg(ssid));
            root.addDebugInfo(qsTr("Using saved password for: %1").arg(ssid));
        }
        
        // Show the exact command being executed
        const cmdStr = cmd.join(" ");
        root.addDebugInfo(qsTr("=== COMMAND TO EXECUTE ==="));
        root.addDebugInfo(qsTr("Command: %1").arg(cmdStr));
        root.addDebugInfo(qsTr("Command array: [%1]").arg(cmd.map((arg, i) => `"${arg}"`).join(", ")));
        root.addDebugInfo(qsTr("Command array length: %1").arg(cmd.length));
        root.addDebugInfo(qsTr("==========================="));
        
        // Set command and start process
        root.addDebugInfo(qsTr("Setting command property..."));
        connectProc.command = cmd;
        const setCmdStr = connectProc.command ? connectProc.command.join(" ") : "null";
        root.addDebugInfo(qsTr("Command property set, value: %1").arg(setCmdStr));
        root.addDebugInfo(qsTr("Command property verified: %1").arg(setCmdStr === cmdStr ? "Match" : "MISMATCH"));
        
        // If we're creating a connection profile, we need to activate it after creation
        const isConnectionAdd = cmd.length > 0 && cmd[0] === "nmcli" && cmd[1] === "connection" && cmd[2] === "add";
        
        // Wait a moment before starting to ensure command is set
        Qt.callLater(() => {
            root.addDebugInfo(qsTr("=== STARTING PROCESS ==="));
            root.addDebugInfo(qsTr("Current running state: %1").arg(connectProc.running));
            root.addDebugInfo(qsTr("Command to run: %1").arg(connectProc.command ? connectProc.command.join(" ") : "NOT SET"));
            root.addDebugInfo(qsTr("Is connection add command: %1").arg(isConnectionAdd));
            connectProc.running = true;
            root.addDebugInfo(qsTr("Process running set to: %1").arg(connectProc.running));
            root.addDebugInfo(qsTr("========================"));
            
            // Check if process actually started after a short delay
            Qt.callLater(() => {
                root.addDebugInfo(qsTr("Process status check (100ms later):"));
                root.addDebugInfo(qsTr("  Running: %1").arg(connectProc.running));
                root.addDebugInfo(qsTr("  Command: %1").arg(connectProc.command ? connectProc.command.join(" ") : "null"));
                if (!connectProc.running) {
                    root.addDebugInfo(qsTr("WARNING: Process did not start!"));
                    root.setConnectionStatus(qsTr("Error: Process failed to start"));
                }
            }, 100);
        });
        
        // Start connection check timer if we have a callback
        if (callback) {
            root.addDebugInfo(qsTr("Starting connection check timer (4 second interval)"));
            connectionCheckTimer.start();
        } else {
            root.addDebugInfo(qsTr("No callback provided - not starting connection check timer"));
        }
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        root.addDebugInfo(qsTr("=== connectToNetworkWithPasswordCheck ==="));
        root.addDebugInfo(qsTr("SSID: %1, isSecure: %2").arg(ssid).arg(isSecure));
        
        // For secure networks, try connecting without password first
        // If connection succeeds (saved password exists), we're done
        // If it fails with password error, callback will be called to show password dialog
        if (isSecure) {
            const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
            root.pendingConnection = { ssid: ssid, bssid: hasBssid ? bssid : "", callback: callback };
            root.addDebugInfo(qsTr("Trying to connect without password (will use saved if available)"));
            // Try connecting without password - will use saved password if available
            connectProc.exec(["nmcli", "device", "wifi", "connect", ssid]);
            // Start timer to check if connection succeeded
            root.addDebugInfo(qsTr("Starting connection check timer"));
            connectionCheckTimer.start();
        } else {
            root.addDebugInfo(qsTr("Network is not secure, connecting directly"));
            connectToNetwork(ssid, "", bssid, null);
        }
        root.addDebugInfo(qsTr("========================================="));
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
    
    function forgetNetwork(ssid: string): void {
        // Delete the connection profile for this network
        // This will remove the saved password and connection settings
        if (ssid && ssid.length > 0) {
            deleteConnectionProc.exec(["nmcli", "connection", "delete", ssid]);
            // Also refresh network list after deletion
            Qt.callLater(() => {
                getNetworks.running = true;
            }, 500);
        }
    }
    
    function hasConnectionProfile(ssid: string): bool {
        // Check if a connection profile exists for this SSID
        // This is synchronous check - returns true if connection exists
        if (!ssid || ssid.length === 0) {
            return false;
        }
        // Use nmcli to check if connection exists
        // We'll use a Process to check, but for now return false
        // The actual check will be done asynchronously
        return false;
    }
    
    property list<string> savedConnections: []
    
    Process {
        id: listConnectionsProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        onExited: {
            if (exitCode === 0) {
                // Parse connection names from output
                const connections = stdout.text.trim().split("\n").filter(name => name.length > 0);
                root.savedConnections = connections;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const connections = text.trim().split("\n").filter(name => name.length > 0);
                root.savedConnections = connections;
            }
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

    function updateWirelessDeviceDetails(): void {
        // Find the wireless interface by looking for wifi devices
        findWirelessInterfaceProc.exec(["nmcli", "device", "status"]);
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
            root.addDebugInfo(qsTr("=== CONNECTION CHECK TIMER (4s) ==="));
            if (root.pendingConnection) {
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                root.addDebugInfo(qsTr("Checking connection status..."));
                root.addDebugInfo(qsTr("  Pending SSID: %1").arg(root.pendingConnection.ssid));
                root.addDebugInfo(qsTr("  Active SSID: %1").arg(root.active ? root.active.ssid : "None"));
                root.addDebugInfo(qsTr("  Connected: %1").arg(connected));
                
                if (!connected && root.pendingConnection.callback) {
                    // Connection didn't succeed after multiple checks, show password dialog
                    root.addDebugInfo(qsTr("Connection failed - calling password dialog callback"));
                    const pending = root.pendingConnection;
                    root.pendingConnection = null;
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    pending.callback();
                } else if (connected) {
                    // Connection succeeded, clear pending
                    root.addDebugInfo(qsTr("Connection succeeded!"));
                    root.setConnectionStatus(qsTr("Connected successfully!"));
                    root.pendingConnection = null;
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                } else {
                    root.addDebugInfo(qsTr("Still connecting..."));
                    root.setConnectionStatus(qsTr("Still connecting..."));
                }
            } else {
                root.addDebugInfo(qsTr("No pending connection"));
            }
            root.addDebugInfo(qsTr("================================"));
        }
    }

    Timer {
        id: immediateCheckTimer
        interval: 500
        repeat: true
        triggeredOnStart: false
        property int checkCount: 0
        
        onRunningChanged: {
            if (running) {
                root.addDebugInfo(qsTr("Immediate check timer started (checks every 500ms)"));
            }
        }
        
        onTriggered: {
            if (root.pendingConnection) {
                checkCount++;
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                root.addDebugInfo(qsTr("Immediate check #%1: Connected=%2").arg(checkCount).arg(connected));
                
                if (connected) {
                    // Connection succeeded, stop timers and clear pending
                    root.addDebugInfo(qsTr("Connection succeeded on check #%1!").arg(checkCount));
                    root.setConnectionStatus(qsTr("Connected successfully!"));
                    connectionCheckTimer.stop();
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    root.pendingConnection = null;
                } else if (checkCount >= 6) {
                    root.addDebugInfo(qsTr("Checked %1 times (3 seconds) - connection taking longer").arg(checkCount));
                    root.setConnectionStatus(qsTr("Connection taking longer than expected..."));
                    // Checked 6 times (3 seconds total), connection likely failed
                    // Stop immediate check, let the main timer handle it
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                }
            } else {
                root.addDebugInfo(qsTr("Immediate check: No pending connection, stopping timer"));
                immediateCheckTimer.stop();
                immediateCheckTimer.checkCount = 0;
            }
        }
    }

    Process {
        id: connectProc

        onRunningChanged: {
            root.addDebugInfo(qsTr("Process running changed to: %1").arg(running));
        }
        
        onStarted: {
            root.addDebugInfo(qsTr("Process started successfully"));
        }
        
        onExited: {
            root.addDebugInfo(qsTr("=== PROCESS EXITED ==="));
            root.addDebugInfo(qsTr("Exit code: %1").arg(exitCode));
            root.addDebugInfo(qsTr("(Exit code 0 = success, non-zero = error)"));
            
            // Check if this was a "connection add" command - if so, we need to activate it
            const wasConnectionAdd = connectProc.command && connectProc.command.length > 0 
                                   && connectProc.command[0] === "nmcli" 
                                   && connectProc.command[1] === "connection" 
                                   && connectProc.command[2] === "add";
            
            if (wasConnectionAdd && exitCode === 0 && root.pendingConnection) {
                // Connection profile was created successfully, now activate it
                const ssid = root.pendingConnection.ssid;
                root.addDebugInfo(qsTr("Connection profile created successfully, now activating: %1").arg(ssid));
                root.setConnectionStatus(qsTr("Activating connection..."));
                
                // Update saved connections list since we just created one
                listConnectionsProc.running = true;
                
                // Activate the connection we just created
                connectProc.command = ["nmcli", "connection", "up", ssid];
                Qt.callLater(() => {
                    connectProc.running = true;
                });
                // Don't start timers yet - wait for activation to complete
                return;
            }
            
            // Refresh network list after connection attempt
            getNetworks.running = true;
            
            // Check if connection succeeded after a short delay (network list needs to update)
            if (root.pendingConnection) {
                if (exitCode === 0) {
                    // Process succeeded, start checking connection status
                    root.setConnectionStatus(qsTr("Connection command succeeded, verifying..."));
                    root.addDebugInfo(qsTr("Command succeeded, checking connection status..."));
                    root.addDebugInfo(qsTr("Starting immediate check timer (500ms intervals)"));
                    immediateCheckTimer.start();
                } else {
                    // Process failed, but wait a moment to see if connection still works
                    root.setConnectionStatus(qsTr("Connection command exited with code %1, checking status...").arg(exitCode));
                    root.addDebugInfo(qsTr("Command exited with error code %1").arg(exitCode));
                    root.addDebugInfo(qsTr("This usually means the command failed"));
                    root.addDebugInfo(qsTr("Checking connection status anyway..."));
                    root.addDebugInfo(qsTr("Starting immediate check timer (500ms intervals)"));
                    immediateCheckTimer.start();
                }
            } else {
                root.addDebugInfo(qsTr("No pending connection - not starting immediate check timer"));
            }
            root.addDebugInfo(qsTr("======================"));
        }
        stdout: SplitParser {
            onRead: {
                getNetworks.running = true;
                // Also log output for debugging
                if (text && text.trim().length > 0) {
                    root.addDebugInfo(qsTr("STDOUT: %1").arg(text.trim()));
                    root.setConnectionStatus(qsTr("Status: %1").arg(text.trim()));
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                root.addDebugInfo(qsTr("=== STDERR OUTPUT ==="));
                if (error && error.length > 0) {
                    // Split error into lines and add each one
                    const errorLines = error.split("\n");
                    for (let i = 0; i < errorLines.length; i++) {
                        const line = errorLines[i].trim();
                        if (line.length > 0) {
                            root.addDebugInfo(qsTr("STDERR: %1").arg(line));
                        }
                    }
                    
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
                    } else if (error && error.length > 0 && !error.includes("Connection activated") && !error.includes("successfully")) {
                        // Log all errors (except success messages)
                        root.setConnectionStatus(qsTr("Error: %1").arg(errorLines[0] || error));
                        // Emit signal for UI to handle
                        root.connectionFailed(root.pendingConnection ? root.pendingConnection.ssid : "");
                    } else if (error && (error.includes("Connection activated") || error.includes("successfully"))) {
                        root.addDebugInfo(qsTr("Connection successful!"));
                        root.setConnectionStatus(qsTr("Connection successful!"));
                    }
                } else {
                    root.addDebugInfo(qsTr("STDERR: (empty)"));
                }
                root.addDebugInfo(qsTr("===================="));
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
        id: deleteConnectionProc
        
        // Delete connection profile - refresh network list and saved connections after deletion
        onExited: {
            // Refresh network list and saved connections after deletion
            getNetworks.running = true;
            listConnectionsProc.running = true;
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0) {
                    // Log error but don't fail - connection might not exist
                    console.warn("Network connection delete error:", error);
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

    Process {
        id: findWirelessInterfaceProc

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output || output.length === 0) {
                    root.wirelessDeviceDetails = null;
                    return;
                }

                // Find the connected wifi interface from device status
                const lines = output.split("\n");
                let wifiInterface = "";
                
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    const parts = line.split(/\s+/);
                    // Format: DEVICE TYPE STATE CONNECTION
                    // Look for wifi devices that are connected
                    if (parts.length >= 3 && parts[1] === "wifi" && parts[2] === "connected") {
                        wifiInterface = parts[0];
                        break;
                    }
                }

                if (wifiInterface && wifiInterface.length > 0) {
                    getWirelessDetailsProc.exec(["nmcli", "device", "show", wifiInterface]);
                } else {
                    root.wirelessDeviceDetails = null;
                }
            }
        }
        onExited: {
            if (exitCode !== 0) {
                root.wirelessDeviceDetails = null;
            }
        }
    }

    Process {
        id: getWirelessDetailsProc

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output || output.length === 0) {
                    root.wirelessDeviceDetails = null;
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
                        } else if (key === "GENERAL.HWADDR") {
                            details.macAddress = value;
                        }
                    }
                }

                root.wirelessDeviceDetails = details;
            }
        }
        onExited: {
            if (exitCode !== 0) {
                root.wirelessDeviceDetails = null;
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
