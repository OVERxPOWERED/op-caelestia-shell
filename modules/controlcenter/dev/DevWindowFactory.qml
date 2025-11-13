pragma Singleton

import "."
import qs.components
import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        devControlCenter.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: devControlCenter

        FloatingWindow {
            id: win

            property alias active: cc.active
            property alias navExpanded: cc.navExpanded

            color: Colours.tPalette.m3surface

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            minimumSize.width: 1000
            minimumSize.height: 600

            implicitWidth: cc.implicitWidth
            implicitHeight: cc.implicitHeight

            title: qsTr("Dev Panel - Wireless")

            DevControlCenter {
                id: cc

                anchors.fill: parent
                screen: win.screen
                floating: true

                function close(): void {
                    win.destroy();
                }
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}

