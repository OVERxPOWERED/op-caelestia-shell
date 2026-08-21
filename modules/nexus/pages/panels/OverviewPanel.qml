pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.overview

PageBase {
    id: root

    readonly property list<MenuItem> tabItems: [
        MenuItem {
            text: qsTr("Workspaces carousel")
            icon: "view_carousel"
        },
        MenuItem {
            text: qsTr("Special scratchpads")
            icon: "layers"
        },
        MenuItem {
            text: qsTr("All windows grid")
            icon: "grid_view"
        }
    ]

    title: qsTr("Taskview")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // View options
        SectionHeader {
            first: true
            text: qsTr("View options")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Active tab")
            subtext: qsTr("Initial view when opening the fullscreen overview")
            menuItems: root.tabItems
            active: root.tabItems[Math.max(0, Math.min(2, OverviewState.activeTab))]
            onSelected: item => OverviewState.activeTab = root.tabItems.indexOf(item)
        }

        // Integration & Controls
        SectionHeader {
            text: qsTr("Shortcuts & Gestures")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: infoLayout.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: infoLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "keyboard"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: qsTr("Shortcut toggle")
                        font: Tokens.font.body.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Press your configured overview hotkey or run `caelestia ipc overview toggle` to open the taskview at any time.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
