import QtQuick
import qs.components
import qs.config

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel

    visible: anchors.topMargin > -implicitHeight - 5
    anchors.topMargin: -5
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    states: State {
        name: "hidden"
        // when: root.visibilities.sidebar && Config.sidebar.enabled

        PropertyChanges {
            root.anchors.topMargin: -implicitHeight - 5
        }
    }

    transitions: Transition {
        Anim {
            target: root.anchors
            property: "topMargin"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Content {
        id: content

        visibilities: root.visibilities
    }
}
