import QtQuick

QtObject {
    readonly property list<string> panes: ["wireless", "debug"]

    required property var root
    property bool floating: false
    property string active: panes[0]
    property int activeIndex: 0
    property bool navExpanded: false

    component Network: QtObject {
        property var active
        property bool showPasswordDialog: false
        property var pendingNetwork
    }

    readonly property Network network: Network {}

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]
}

