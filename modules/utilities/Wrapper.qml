import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities

    visible: height > 0
    implicitHeight: 0
    implicitWidth: Config.utilities.sizes.width

    states: State {
        name: "visible"
        when: root.visibilities.utilities

        PropertyChanges {
            root.implicitHeight: content.implicitHeight + Appearance.padding.large * 2
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Content {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large

        visibilities: root.visibilities
    }
}
