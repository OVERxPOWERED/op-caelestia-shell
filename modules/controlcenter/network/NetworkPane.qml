pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.effects
import qs.components.containers
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        NetworkList {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            session: root.session
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Loader {
            id: loader

            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2

            sourceComponent: root.session.network.active ? details : settings

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: settings

            Settings {
                session: root.session
            }
        }

        Component {
            id: details

            Details {
                session: root.session
            }
        }
    }
}
