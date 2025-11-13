import ".."
import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string title
    property string description: ""
    property bool expanded: false

    signal toggleRequested

    spacing: Appearance.spacing.small / 2
    Layout.fillWidth: true

    Item {
        id: sectionHeaderItem
        Layout.fillWidth: true
        Layout.preferredHeight: sectionHeader.implicitHeight

        ColumnLayout {
            id: sectionHeader
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: root.title
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
                }

                MaterialIcon {
                    text: "expand_more"
                    rotation: root.expanded ? 180 : 0
                    color: Colours.palette.m3onSurface
                    Behavior on rotation {
                        Anim {}
                    }
                }
            }

            StateLayer {
                anchors.fill: parent
                anchors.leftMargin: -Appearance.padding.normal
                anchors.rightMargin: -Appearance.padding.normal
                function onClicked(): void {
                    root.toggleRequested();
                    root.expanded = !root.expanded;
                }
            }

            StyledText {
                visible: root.expanded && root.description !== ""
                text: root.description
                color: Colours.palette.m3outline
                Layout.fillWidth: true
            }
        }
    }

    default property alias content: contentColumn.data

    ColumnLayout {
        id: contentColumn
        Layout.fillWidth: true
        visible: root.expanded
        spacing: Appearance.spacing.small / 2
    }
}

