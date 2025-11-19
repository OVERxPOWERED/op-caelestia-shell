pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
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

        WirelessList {
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

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"

            Loader {
                id: loader

                property var pane: root.session.network.active
                property string paneId: pane ? (pane.ssid || pane.bssid || "") : ""
                property Component targetComponent: settings
                property Component nextComponent: settings

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2

                opacity: 1
                scale: 1
                transformOrigin: Item.Center

                clip: false
                asynchronous: true
                sourceComponent: loader.targetComponent

                Component.onCompleted: {
                    targetComponent = pane ? details : settings;
                    nextComponent = targetComponent;
                }

                Behavior on paneId {
                    PaneTransition {
                        target: loader
                        propertyActions: [
                            PropertyAction {
                                target: loader
                                property: "targetComponent"
                                value: loader.nextComponent
                            }
                        ]
                    }
                }

                onPaneChanged: {
                    nextComponent = pane ? details : settings;
                    paneId = pane ? (pane.ssid || pane.bssid || "") : "";
                }
            }
        }

        InnerBorder {
            id: rightBorder

            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: settings

            StyledFlickable {
                flickableDirection: Flickable.VerticalFlick
                contentHeight: settingsInner.height
                clip: true

                WirelessSettings {
                    id: settingsInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    session: root.session
                }
            }
        }

        Component {
            id: details

            WirelessDetails {
                session: root.session
            }
        }
    }

    WirelessPasswordDialog {
        anchors.fill: parent
        session: root.session
        z: 1000
    }
}