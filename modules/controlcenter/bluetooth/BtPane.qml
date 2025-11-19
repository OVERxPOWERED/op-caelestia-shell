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

                Loader {
                    id: rightLoader

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large * 2

                    asynchronous: true
                    sourceComponent: rightBtPane.pane ? details : settings
                }

                Behavior on pane {
                    SequentialAnimation {
                        ParallelAnimation {
                            Anim {
                                target: rightLoader
                                property: "opacity"
                                to: 0
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                            Anim {
                                target: rightLoader
                                property: "scale"
                                to: 0.8
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                        }
                        PropertyAction {}
                        ParallelAnimation {
                            Anim {
                                target: rightLoader
                                property: "opacity"
                                to: 1
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                            Anim {
                                target: rightLoader
                                property: "scale"
                                to: 1
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }

                Connections {
                    target: root.session.bt
                    function onActiveChanged() {
                        rightBtPane.pane = root.session.bt.active;
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

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal / 2
        easing.type: Easing.BezierSpline
    }
}
