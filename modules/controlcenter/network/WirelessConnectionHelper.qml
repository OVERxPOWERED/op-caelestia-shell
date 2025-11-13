pragma ComponentBehavior: Bound

import ".."
import qs.services
import QtQuick

QtObject {
    id: root

    required property Session session

    function connectToNetwork(network: var): void {
        if (!network) {
            return;
        }

        // If already connected to a different network, disconnect first
        if (Network.active && Network.active.ssid !== network.ssid) {
            Network.disconnectFromNetwork();
            Qt.callLater(() => {
                performConnect(network);
            });
        } else {
            performConnect(network);
        }
    }

    function performConnect(network: var): void {
        if (network.isSecure) {
            // Try connecting without password first (in case it's saved)
            Network.connectToNetworkWithPasswordCheck(
                network.ssid,
                network.isSecure,
                () => {
                    // Callback: connection failed, show password dialog
                    root.session.network.showPasswordDialog = true;
                    root.session.network.pendingNetwork = network;
                },
                network.bssid
            );
        } else {
            Network.connectToNetwork(network.ssid, "", network.bssid, null);
        }
    }
}

