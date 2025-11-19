pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    anchors.fill: parent

    SplitPaneLayout {
        anchors.fill: parent

        leftContent: Component {
            DeviceList {
                anchors.fill: parent
                session: root.session
            }
        }

        rightContent: Component {
            Item {
                id: rightBtPane

                property BluetoothDevice pane: root.session.bt.active
                property string paneId: pane ? (pane.address || "") : ""
                property Component targetComponent: settings
                property Component nextComponent: settings

                function getComponentForPane() {
                    return pane ? details : settings;
                }

                Component.onCompleted: {
                    targetComponent = getComponentForPane();
                    nextComponent = targetComponent;
                }

                Loader {
                    id: rightLoader

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large * 2

                    asynchronous: true
                    sourceComponent: rightBtPane.targetComponent
                }

                Behavior on paneId {
                    PaneTransition {
                        target: rightLoader
                        propertyActions: [
                            PropertyAction {
                                target: rightBtPane
                                property: "targetComponent"
                                value: rightBtPane.nextComponent
                            }
                        ]
                    }
                }

                Connections {
                    target: root.session.bt
                    function onActiveChanged() {
                        rightBtPane.pane = root.session.bt.active;
                        rightBtPane.nextComponent = rightBtPane.getComponentForPane();
                        rightBtPane.paneId = pane ? (pane.address || "") : "";
                    }
                }
            }
        }
    }

    Component {
        id: settings

        StyledFlickable {
            id: settingsFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: settingsFlickable
            }

            Settings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    Component {
        id: details

        Details {
            session: root.session
        }
    }
}
