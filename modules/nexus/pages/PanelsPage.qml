pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Panels")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            label: qsTr("Dashboard")
            status: Config.dashboard.enabled ? qsTr("Enabled") : qsTr("Disabled")
            target: 1
        }

        NavRow {
            icon: "dock_to_bottom"
            label: qsTr("Taskbar")
            status: Config.bar.persistent ? qsTr("Always visible") : qsTr("Reveal on hover")
            target: 2
        }

        NavRow {
            icon: "apps"
            label: qsTr("Launcher")
            status: Config.launcher.enabled ? qsTr("Enabled") : qsTr("Disabled")
            target: 3
        }

        NavRow {
            last: true
            icon: "dock_to_right"
            label: qsTr("Sidebar")
            status: Config.sidebar.enabled ? qsTr("Enabled") : qsTr("Disabled")
            target: 4
        }
    }

    component NavRow: ConnectedRect {
        id: navRow

        property alias icon: icon.text
        property alias label: label.text
        property alias status: status.text
        property int target

        Layout.fillWidth: true
        implicitHeight: navLayout.implicitHeight + navLayout.anchors.topMargin + navLayout.anchors.bottomMargin

        StateLayer {
            onClicked: root.nState.openSubPage(navRow.target)
        }

        RowLayout {
            id: navLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            anchors.topMargin: Tokens.padding.medium
            anchors.bottomMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                id: icon

                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    id: status

                    Layout.fillWidth: true
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                    animate: true
                }
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.icon.medium
            }
        }
    }
}
