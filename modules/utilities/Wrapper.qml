pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item sidebar
    required property BarPopouts.Wrapper popouts

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode

        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: visibilities.sidebar || (visibilities.utilities && Config.utilities.enabled && !(visibilities.session && Config.session.enabled))
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight + content.anchors.margins * 2
    implicitWidth: sidebar.visible ? sidebar.width : Config.utilities.sizes.width

    Behavior on offsetScale {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Appearance.padding.large

        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - content.anchors.margins * 2
            props: root.props
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
