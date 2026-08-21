pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import ".."

StyledRect {
    id: root

    readonly property list<var> tabs: [
        { name: qsTr("Workspaces"), icon: "view_carousel", tabId: 0 },
        { name: qsTr("Special"), icon: "crop_square", tabId: 1 },
        { name: qsTr("All Windows"), icon: "grid_view", tabId: 2 }
    ]

    implicitWidth: row.implicitWidth + Tokens.padding.extraSmall * 2
    implicitHeight: 38
    radius: Tokens.rounding.full
    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 0)
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    // Sliding indicator
    StyledRect {
        id: indicator
        y: Tokens.padding.extraSmall
        height: root.height - Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer
        border.width: 1
        border.color: Colours.palette.m3primary

        // Calculate x position based on active tab item
        x: {
            let offset = Tokens.padding.extraSmall;
            for (let i = 0; i < OverviewState.activeTab && i < row.children.length; i++) {
                offset += row.children[i].width + row.spacing;
            }
            return offset;
        }
        width: row.children[OverviewState.activeTab]?.width ?? 100

        Behavior on x { Anim {} }
        Behavior on width { Anim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: root.tabs

            Item {
                id: tabItem
                required property var modelData
                required property int index

                readonly property bool isSelected: OverviewState.activeTab === this.modelData.tabId

                implicitWidth: contentRow.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: root.height - Tokens.padding.extraSmall * 2

                Row {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: tabItem.modelData.icon
                        fontStyle: Tokens.font.icon.medium
                        color: tabItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: tabItem.modelData.name
                        font.pixelSize: 12
                        font.weight: tabItem.isSelected ? Font.Bold : Font.Medium
                        color: tabItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    onClicked: {
                        OverviewState.activeTab = tabItem.modelData.tabId;
                    }
                }
            }
        }
    }
}
