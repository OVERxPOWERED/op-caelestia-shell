pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    readonly property Props props: Props {}

    visible: anchors.rightMargin > -implicitWidth - 5
    anchors.rightMargin: -implicitWidth - 5
    implicitWidth: Config.sidebar.sizes.width

    states: State {
        name: "visible"
        when: root.visibilities.sidebar && Config.sidebar.enabled

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
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
        // Transition {
        //     from: "visible"
        //     to: ""

        //     Anim {
        //         target: root
        //         property: "implicitWidth"
        //         easing.bezierCurve: root.panels.osd.width > 0 || root.panels.session.width > 0 ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
        //     }
        // }


    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Appearance.padding.large
        anchors.bottomMargin: 0

        active: true
        Component.onCompleted: active = Qt.binding(() => (root.visibilities.sidebar && Config.sidebar.enabled) || root.visible)

        sourceComponent: Content {
            implicitWidth: Config.sidebar.sizes.width - Appearance.padding.large * 2
            props: root.props
            visibilities: root.visibilities
        }
    }
}
