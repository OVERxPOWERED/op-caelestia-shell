import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label

    activeColour: type === IconTextButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    inactiveColour: type === IconTextButton.Filled ? Colours.tPalette.m3surfaceContainer : Colours.palette.m3secondaryContainer
    activeOnColour: type === IconTextButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondary
    inactiveOnColour: type === IconTextButton.Filled ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
            color: root.onColour
            fill: root.internalChecked ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: -Math.round(iconLabel.fontInfo.pointSize * 0.0575)
            color: root.onColour
        }
    }
}
