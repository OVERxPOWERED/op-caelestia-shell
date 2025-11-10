pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

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

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: getNetworks.running = true
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
