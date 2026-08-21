pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.dock && Config.dock.enabled

    property real offsetScale: shouldBeActive ? 0 : 1
    property bool editMode: false
    property bool contextMenuOpen: false
    property real contextMenuHeight: 0

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 300 // Fallback
    width: implicitWidth
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            editMode: root.editMode
            onEditModeChanged: root.editMode = editMode
            onContextMenuOpenChanged: root.contextMenuOpen = contextMenuOpen
            onContextMenuHeightChanged: root.contextMenuHeight = contextMenuHeight
        }
    }
}
