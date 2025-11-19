import Quickshell.Bluetooth
import QtQuick

QtObject {
    id: root

    // Active selected device
    property BluetoothDevice active: null

    // Current adapter being used
    property BluetoothAdapter currentAdapter: Bluetooth.defaultAdapter

    // UI state flags
    property bool editingAdapterName: false
    property bool fabMenuOpen: false
    property bool editingDeviceName: false
}

