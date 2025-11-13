pragma ComponentBehavior: Bound

import "."
import ".."
import qs.components
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {
    id: root

    required property DevSession session

    color: "transparent"

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height

        Pane {
            index: 0
            sourceComponent: DevWirelessPane {
                session: root.session
            }
        }

        Pane {
            index: 1
            sourceComponent: DevDebugPane {
                session: root.session
            }
        }

        Behavior on y {
            Anim {}
        }
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent

        implicitWidth: root.width
        implicitHeight: root.height

        Loader {
            id: loader

            anchors.fill: parent
            clip: true
            asynchronous: true
            active: {
                if (root.session.activeIndex === pane.index)
                    return true;

                const ly = -layout.y;
                const ty = pane.index * root.height;
                return ly + root.height > ty && ly < ty + root.height;
            }
        }
    }
}

