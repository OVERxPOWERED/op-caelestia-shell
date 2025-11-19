import QtQuick

QtObject {
    id: root

    // Active selected wireless network
    property var active: null

    // Password dialog state
    property bool showPasswordDialog: false
    property var pendingNetwork: null
}

