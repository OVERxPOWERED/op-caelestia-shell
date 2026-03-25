pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    readonly property real nonAnimWidth: content.implicitWidth

    visible: anchors.rightMargin > -implicitWidth - 1
    anchors.rightMargin: -implicitWidth - 1
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibilities.session && Config.session.enabled

        PropertyChanges {
            root.anchors.rightMargin: 0
        }
    }

    transitions: [
        Transition {
            // from: ""
            // to: "visible"

            Anim {
                target: root.anchors
                property: "rightMargin"
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
        // Transition {
        //     from: "visible"
        //     to: ""

        //     Anim {
        //         target: root
        //         property: "implicitWidth"
        //         easing.bezierCurve: root.panels.osd.width > 0 ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
        //     }
        // }


    ]

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        Component.onCompleted: active = Qt.binding(() => (root.visibilities.session && Config.session.enabled) || root.visible)

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
