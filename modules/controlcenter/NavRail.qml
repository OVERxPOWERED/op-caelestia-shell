pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitWidth: layout.implicitWidth + Appearance.padding.larger * 4
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.padding.larger * 2
        spacing: Appearance.spacing.normal

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                layout.spacing: Appearance.spacing.small
            }
        }

        transitions: Transition {
            Anim {
                properties: "spacing"
            }
        }

        NavItem {
            Layout.topMargin: Appearance.spacing.large * 2
            icon: "router"
            label: "network"
        }

        NavItem {
            icon: "settings_bluetooth"
            label: "bluetooth"
        }

        NavItem {
            icon: "volume_up"
            label: "audio"
        }

        NavItem {
            icon: "palette"
            label: "appearance"
        }

        NavItem {
            icon: "task_alt"
            label: "taskbar"
        }

        NavItem {
            icon: "apps"
            label: "launcher"
        }
    }

    component NavItem: Item {
        id: item

        required property string icon
        required property string label
        readonly property bool active: root.session.active === label

        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight + smallLabel.implicitHeight + smallLabel.anchors.topMargin

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                expandedLabel.opacity: 1
                smallLabel.opacity: 0
                background.implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2 + expandedLabel.anchors.leftMargin + expandedLabel.implicitWidth
                background.implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2
                item.implicitHeight: background.implicitHeight
            }
        }

        transitions: Transition {
            Anim {
                property: "opacity"
                duration: Appearance.anim.durations.small
            }

            Anim {
                properties: "implicitWidth,implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        StyledRect {
            id: background

            radius: Appearance.rounding.full
            color: Qt.alpha(Colours.palette.m3secondaryContainer, item.active ? 1 : 0)

            implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2
            implicitHeight: icon.implicitHeight + Appearance.padding.small

            StateLayer {
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    root.session.active = item.label;
                }
            }

            MaterialIcon {
                id: icon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.padding.large

                text: item.icon
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
                fill: item.active ? 1 : 0

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                id: expandedLabel

                anchors.left: icon.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.spacing.normal

                opacity: 0
                text: item.label
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.capitalization: Font.Capitalize
            }

            StyledText {
                id: smallLabel

                anchors.horizontalCenter: icon.horizontalCenter
                anchors.top: icon.bottom
                anchors.topMargin: Appearance.spacing.small / 2

                text: item.label
                font.pointSize: Appearance.font.size.small
                font.capitalization: Font.Capitalize
            }
        }
    }
}
