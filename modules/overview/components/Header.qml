pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import ".."

Item {
    id: root

    signal closeRequested

    implicitWidth: parent.width
    implicitHeight: segmentedNav.implicitHeight + Tokens.padding.large * 2

    // Centered Segmented Navigation Tabs
    SegmentedNav {
        id: segmentedNav
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.large
    }

    // Top Right Controls (Layout Switcher & Close)
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        // Layout Toggle Pill (Carousel vs Grid) - visible on Workspaces tab
        StyledRect {
            visible: OverviewState.activeTab === 0
            implicitWidth: layoutRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: 32
            radius: Tokens.rounding.full
            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 0)
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Row {
                id: layoutRow
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: OverviewState.gridMode ? "view_carousel" : "grid_view"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: OverviewState.gridMode ? qsTr("Carousel") : qsTr("Grid")
                    font.pixelSize: 12
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.full
                onClicked: OverviewState.gridMode = !OverviewState.gridMode
            }
        }

        // Close Pill Button
        StyledRect {
            implicitWidth: closeRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: 32
            radius: Tokens.rounding.full
            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 0)
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Row {
                id: closeRow
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitWidth: 20
                    implicitHeight: 18
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Esc")
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                StyledText {
                    text: qsTr("Close")
                    font.pixelSize: 12
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.full
                onClicked: root.closeRequested()
            }
        }
    }
}
