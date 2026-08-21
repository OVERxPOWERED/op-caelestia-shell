#!/usr/bin/env python3
"""Bluetooth pairing agent for Caelestia shell.

Registers as a BlueZ Agent1 on the system D-Bus and communicates
with the Quickshell UI via a Unix domain socket using newline-delimited JSON.

Protocol (agent → QML):
  {"type": "request_confirmation", "device": "...", "name": "...", "passkey": "123456"}
  {"type": "request_passkey",      "device": "...", "name": "..."}
  {"type": "request_pin",          "device": "...", "name": "..."}
  {"type": "request_authorization","device": "...", "name": "..."}
  {"type": "display_passkey",      "device": "...", "name": "...", "passkey": "123456", "entered": 3}
  {"type": "cancel"}

Protocol (QML → agent):
  {"type": "confirm"}
  {"type": "reject"}
  {"type": "passkey", "value": "123456"}
  {"type": "pin",     "value": "1234"}
"""

import json
import os
import signal
import socket
import sys
import threading

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

AGENT_PATH = "/caelestia/bluetooth/agent"
AGENT_CAPABILITY = "KeyboardDisplay"
SOCKET_PATH = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"),
    "caelestia-bt-agent.sock",
)
RESPONSE_TIMEOUT = 30  # seconds


def get_device_name(device_path: str) -> str:
    """Resolve a BlueZ device object path to its human-readable name."""
    try:
        bus = dbus.SystemBus()
        obj = bus.get_object("org.bluez", device_path)
        props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
        name = props.Get("org.bluez.Device1", "Name")
        return str(name)
    except Exception:
        # Fallback: extract MAC from path (dev_XX_XX_XX_XX_XX_XX → XX:XX:...)
        try:
            mac_part = device_path.split("/")[-1].replace("dev_", "").replace("_", ":")
            return mac_part
        except Exception:
            return "Unknown device"


class SocketBridge:
    """Manages the Unix socket connection to the Quickshell UI."""

    def __init__(self):
        self._server: socket.socket | None = None
        self._client: socket.socket | None = None
        self._lock = threading.Lock()
        self._recv_buffer = ""

    def start(self):
        """Start listening on the Unix socket."""
        # Clean up stale socket
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)

        self._server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server.bind(SOCKET_PATH)
        os.chmod(SOCKET_PATH, 0o600)
        self._server.listen(1)
        self._server.setblocking(False)

        # Watch for incoming connections via GLib
        GLib.io_add_watch(
            self._server.fileno(),
            GLib.IO_IN,
            self._on_incoming_connection,
        )
        print(f"[bt-agent] Listening on {SOCKET_PATH}", flush=True)

    def _on_incoming_connection(self, _fd, _condition):
        """Accept a new QML client connection."""
        try:
            client, _ = self._server.accept()
            with self._lock:
                if self._client:
                    try:
                        self._client.close()
                    except Exception:
                        pass
                self._client = client
                self._recv_buffer = ""
            print("[bt-agent] QML client connected", flush=True)
        except Exception as e:
            print(f"[bt-agent] Accept error: {e}", flush=True)
        return True  # Keep watching

    def send(self, msg: dict):
        """Send a JSON message to the QML client."""
        with self._lock:
            if not self._client:
                print("[bt-agent] No QML client connected, cannot send", flush=True)
                return
            try:
                data = json.dumps(msg, separators=(",", ":")) + "\n"
                self._client.sendall(data.encode("utf-8"))
            except (BrokenPipeError, OSError) as e:
                print(f"[bt-agent] Send error: {e}", flush=True)
                self._client = None

    def wait_for_response(self, timeout: float = RESPONSE_TIMEOUT) -> dict | None:
        """Block until a JSON response arrives from the QML client, or timeout."""
        with self._lock:
            client = self._client
        if not client:
            return None

        client.settimeout(timeout)
        try:
            while True:
                # Check buffer first
                if "\n" in self._recv_buffer:
                    line, self._recv_buffer = self._recv_buffer.split("\n", 1)
                    return json.loads(line)

                chunk = client.recv(4096)
                if not chunk:
                    # Client disconnected
                    with self._lock:
                        self._client = None
                    return None
                self._recv_buffer += chunk.decode("utf-8")
        except socket.timeout:
            print("[bt-agent] Response timeout", flush=True)
            return None
        except (json.JSONDecodeError, OSError) as e:
            print(f"[bt-agent] Response error: {e}", flush=True)
            return None

    def stop(self):
        """Clean up sockets."""
        with self._lock:
            if self._client:
                try:
                    self._client.close()
                except Exception:
                    pass
                self._client = None
        if self._server:
            try:
                self._server.close()
            except Exception:
                pass
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)


class BluezAgent(dbus.service.Object):
    """Implementation of org.bluez.Agent1 interface."""

    def __init__(self, bus, bridge: SocketBridge):
        super().__init__(bus, AGENT_PATH)
        self._bridge = bridge

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="os", out_signature=""
    )
    def RequestConfirmation(self, device, passkey):
        """Ask user to confirm a numeric passkey for pairing."""
        name = get_device_name(device)
        passkey_str = f"{passkey:06d}"
        print(f"[bt-agent] RequestConfirmation: {name} passkey={passkey_str}", flush=True)

        self._bridge.send({
            "type": "request_confirmation",
            "device": str(device),
            "name": name,
            "passkey": passkey_str,
        })

        response = self._bridge.wait_for_response()
        if response and response.get("type") == "confirm":
            print(f"[bt-agent] User confirmed pairing with {name}", flush=True)
            return  # Success — BlueZ continues pairing
        else:
            print(f"[bt-agent] User rejected pairing with {name}", flush=True)
            raise dbus.exceptions.DBusException(
                "org.bluez.Error.Rejected", "Pairing rejected by user"
            )

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="o", out_signature="u"
    )
    def RequestPasskey(self, device):
        """Ask user to enter a numeric passkey."""
        name = get_device_name(device)
        print(f"[bt-agent] RequestPasskey: {name}", flush=True)

        self._bridge.send({
            "type": "request_passkey",
            "device": str(device),
            "name": name,
        })

        response = self._bridge.wait_for_response()
        if response and response.get("type") == "passkey":
            value = int(response["value"])
            print(f"[bt-agent] User entered passkey for {name}", flush=True)
            return dbus.UInt32(value)
        else:
            print(f"[bt-agent] User cancelled passkey entry for {name}", flush=True)
            raise dbus.exceptions.DBusException(
                "org.bluez.Error.Rejected", "Passkey entry cancelled"
            )

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="o", out_signature="s"
    )
    def RequestPinCode(self, device):
        """Ask user to enter a PIN code."""
        name = get_device_name(device)
        print(f"[bt-agent] RequestPinCode: {name}", flush=True)

        self._bridge.send({
            "type": "request_pin",
            "device": str(device),
            "name": name,
        })

        response = self._bridge.wait_for_response()
        if response and response.get("type") == "pin":
            value = str(response["value"])
            print(f"[bt-agent] User entered PIN for {name}", flush=True)
            return value
        else:
            print(f"[bt-agent] User cancelled PIN entry for {name}", flush=True)
            raise dbus.exceptions.DBusException(
                "org.bluez.Error.Rejected", "PIN entry cancelled"
            )

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="o", out_signature=""
    )
    def RequestAuthorization(self, device):
        """Ask user to authorize a pairing request (no passkey)."""
        name = get_device_name(device)
        print(f"[bt-agent] RequestAuthorization: {name}", flush=True)

        self._bridge.send({
            "type": "request_authorization",
            "device": str(device),
            "name": name,
        })

        response = self._bridge.wait_for_response()
        if response and response.get("type") == "confirm":
            print(f"[bt-agent] User authorized {name}", flush=True)
            return
        else:
            print(f"[bt-agent] User rejected authorization for {name}", flush=True)
            raise dbus.exceptions.DBusException(
                "org.bluez.Error.Rejected", "Authorization rejected"
            )

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="os", out_signature=""
    )
    def AuthorizeService(self, device, uuid):
        """Auto-authorize service access (standard behavior)."""
        name = get_device_name(device)
        print(f"[bt-agent] AuthorizeService: {name} uuid={uuid} (auto-accepted)", flush=True)
        return

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="ouq", out_signature=""
    )
    def DisplayPasskey(self, device, passkey, entered):
        """Display a passkey and progress for the user to enter on the remote device."""
        name = get_device_name(device)
        passkey_str = f"{passkey:06d}"
        print(f"[bt-agent] DisplayPasskey: {name} passkey={passkey_str} entered={entered}", flush=True)

        self._bridge.send({
            "type": "display_passkey",
            "device": str(device),
            "name": name,
            "passkey": passkey_str,
            "entered": int(entered),
        })

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="", out_signature=""
    )
    def Cancel(self):
        """BlueZ cancelled the current request."""
        print("[bt-agent] Cancel", flush=True)
        self._bridge.send({"type": "cancel"})

    @dbus.service.method(
        "org.bluez.Agent1", in_signature="", out_signature=""
    )
    def Release(self):
        """Agent unregistered."""
        print("[bt-agent] Released", flush=True)


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    bridge = SocketBridge()
    bridge.start()

    agent = BluezAgent(bus, bridge)

    # Register with BlueZ
    manager = dbus.Interface(
        bus.get_object("org.bluez", "/org/bluez"),
        "org.bluez.AgentManager1",
    )
    manager.RegisterAgent(AGENT_PATH, AGENT_CAPABILITY)
    manager.RequestDefaultAgent(AGENT_PATH)
    print(f"[bt-agent] Registered as default agent (capability={AGENT_CAPABILITY})", flush=True)

    loop = GLib.MainLoop()

    def shutdown(_signum=None, _frame=None):
        print("[bt-agent] Shutting down...", flush=True)
        try:
            manager.UnregisterAgent(AGENT_PATH)
        except Exception:
            pass
        bridge.stop()
        loop.quit()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    try:
        loop.run()
    except KeyboardInterrupt:
        shutdown()


if __name__ == "__main__":
    main()
