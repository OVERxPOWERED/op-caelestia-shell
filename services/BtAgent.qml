pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services

Singleton {
    id: root

    // --- Public properties for UI binding ---
    property bool active: false
    property string requestType: ""    // "confirmation", "passkey", "pin", "display", "authorization"
    property string deviceName: ""
    property string devicePath: ""
    property string passkey: ""
    property int entered: 0

    // --- Public methods for UI actions ---
    function confirm(): void {
        sendMessage({"type": "confirm"});
        resetState();
    }

    function reject(): void {
        sendMessage({"type": "reject"});
        resetState();
    }

    function sendPasskey(value: string): void {
        sendMessage({"type": "passkey", "value": value});
        resetState();
    }

    function sendPin(value: string): void {
        sendMessage({"type": "pin", "value": value});
        resetState();
    }

    // --- Internal ---
    function resetState(): void {
        active = false;
        requestType = "";
        deviceName = "";
        devicePath = "";
        passkey = "";
        entered = 0;
    }

    function sendMessage(msg: var): void {
        if (sock.connected) {
            sock.write(JSON.stringify(msg) + "\n");
            sock.flush();
        }
    }

    function handleMessage(data: string): void {
        let msg;
        try {
            msg = JSON.parse(data);
        } catch (e) {
            console.warn("[BtAgent] Failed to parse message:", data);
            return;
        }

        switch (msg.type) {
        case "request_confirmation":
            root.devicePath = msg.device ?? "";
            root.deviceName = msg.name ?? "Unknown";
            root.passkey = msg.passkey ?? "";
            root.requestType = "confirmation";
            root.active = true;
            Toaster.toast(qsTr("Bluetooth pairing"), qsTr("Confirm pairing with %1").arg(root.deviceName), "bluetooth");
            break;
        case "request_passkey":
            root.devicePath = msg.device ?? "";
            root.deviceName = msg.name ?? "Unknown";
            root.requestType = "passkey";
            root.active = true;
            Toaster.toast(qsTr("Bluetooth pairing"), qsTr("Enter passkey for %1").arg(root.deviceName), "bluetooth");
            break;
        case "request_pin":
            root.devicePath = msg.device ?? "";
            root.deviceName = msg.name ?? "Unknown";
            root.requestType = "pin";
            root.active = true;
            Toaster.toast(qsTr("Bluetooth pairing"), qsTr("Enter PIN for %1").arg(root.deviceName), "bluetooth");
            break;
        case "request_authorization":
            root.devicePath = msg.device ?? "";
            root.deviceName = msg.name ?? "Unknown";
            root.requestType = "authorization";
            root.active = true;
            Toaster.toast(qsTr("Bluetooth pairing"), qsTr("%1 wants to pair").arg(root.deviceName), "bluetooth");
            break;
        case "display_passkey":
            root.devicePath = msg.device ?? "";
            root.deviceName = msg.name ?? "Unknown";
            root.passkey = msg.passkey ?? "";
            root.entered = msg.entered ?? 0;
            root.requestType = "display";
            root.active = true;
            break;
        case "cancel":
            root.resetState();
            break;
        default:
            console.warn("[BtAgent] Unknown message type:", msg.type);
        }
    }

    // --- Agent process lifecycle ---
    Process {
        id: agentProc

        command: ["python3", "-u", Quickshell.shellPath("scripts/bt-agent.py")]
        running: true

        stdout: SplitParser {
            onRead: data => console.log("[bt-agent/out]", data)
        }

        stderr: SplitParser {
            onRead: data => console.warn("[bt-agent/err]", data)
        }

        onStarted: { // qmllint disable signal-handler-parameters
            console.log("[BtAgent] Agent process started");
            socketConnectTimer.start();
        }

        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            console.warn("[BtAgent] Agent exited with code", exitCode, "- restarting in 3s");
            root.resetState();
            sock.connected = false;
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer

        interval: 3000
        onTriggered: agentProc.running = true
    }

    // Delay socket connection until agent has time to create the socket
    Timer {
        id: socketConnectTimer

        interval: 1000
        onTriggered: sock.connected = true
    }

    // --- Socket connection to agent ---
    Socket {
        id: sock

        path: (Quickshell.env("XDG_RUNTIME_DIR") ?? ("/run/user/" + Quickshell.env("UID"))) + "/caelestia-bt-agent.sock"
        connected: false // Will be set to true by socketConnectTimer

        parser: SplitParser {
            splitMarker: "\n"
            onRead: data => root.handleMessage(data)
        }

        onConnectionStateChanged: {
            if (!connected) {
                console.warn("[BtAgent] Socket disconnected, reconnecting in 2s");
                reconnectTimer.start();
            } else {
                console.log("[BtAgent] Socket connected to agent");
            }
        }
    }

    Timer {
        id: reconnectTimer

        interval: 2000
        onTriggered: sock.connected = true
    }
}

