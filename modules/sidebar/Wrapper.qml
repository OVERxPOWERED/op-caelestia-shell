pragma ComponentBehavior: Bound

import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities
    required property var panels

    visible: width > 0
    implicitWidth: 0
    implicitHeight: 0

    states: State {
        name: "visible"
        when: root.visibilities.sidebar && Config.sidebar.enabled

        PropertyChanges {
            root.implicitWidth: Config.sidebar.sizes.width
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: root.panels.osd.width > 0 || root.panels.session.width > 0 ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large

        visible: false
        active: true
        Component.onCompleted: active = Qt.binding(() => (root.visibilities.sidebar && Config.sidebar.enabled) || root.visible)

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
