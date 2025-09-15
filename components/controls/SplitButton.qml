import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Row {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: Appearance.padding.normal
    property real verticalPadding: Appearance.padding.smaller
    property int type: SplitButton.Filled
    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    property alias menu: menu

    property color colour: type == SplitButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
    property color textColour: type == SplitButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer

    spacing: Math.floor(Appearance.spacing.small / 2)

    StyledRect {
        radius: implicitHeight / 2
        topRightRadius: Appearance.rounding.small / 2
        bottomRightRadius: Appearance.rounding.small / 2
        color: root.colour

        implicitWidth: textRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: expandBtn.implicitHeight

        StateLayer {
            id: stateLayer

            rect.topRightRadius: parent.topRightRadius
            rect.bottomRightRadius: parent.bottomRightRadius
            color: root.textColour

            function onClicked(): void {
                root.active?.clicked();
            }
        }

        RowLayout {
            id: textRow

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Math.floor(root.verticalPadding / 4)
            spacing: Appearance.spacing.small

            MaterialIcon {
                id: iconLabel

                Layout.alignment: Qt.AlignVCenter
                animate: true
                text: root.active?.activeIcon ?? ""
                color: root.textColour
                fill: 1
            }

            StyledText {
                id: label

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                animate: true
                text: root.active?.activeText ?? ""
                color: root.textColour
                clip: true

                Behavior on Layout.preferredWidth {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }
        }
    }

    StyledRect {
        id: expandBtn

        property real rad: root.expanded ? implicitHeight / 2 : Appearance.rounding.small / 2

        radius: implicitHeight / 2
        topLeftRadius: rad
        bottomLeftRadius: rad
        color: root.colour

        implicitWidth: implicitHeight
        implicitHeight: expandIcon.implicitHeight + root.verticalPadding * 2

        StateLayer {
            id: expandStateLayer

            rect.topRightRadius: parent.topRightRadius
            rect.bottomRightRadius: parent.bottomRightRadius
            color: root.textColour

            function onClicked(): void {
                root.expanded = !root.expanded;
            }
        }

        MaterialIcon {
            id: expandIcon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.expanded ? 0 : -Math.floor(root.verticalPadding / 4)

            text: "expand_more"
            color: root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on anchors.horizontalCenterOffset {
                Anim {}
            }

            Behavior on rotation {
                Anim {}
            }
        }

        Behavior on rad {
            Anim {}
        }

        Menu {
            id: menu

            anchors.top: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: Appearance.spacing.small
        }
    }
}
