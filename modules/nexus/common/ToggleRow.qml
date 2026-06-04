import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledSwitch {
    id: root

    property string subtext
    property bool first
    property bool last

    implicitWidth: implicitContentWidth + implicitIndicatorWidth + Tokens.padding.largeIncreased * 2
    implicitHeight: Math.max(implicitContentHeight, implicitIndicatorHeight) + Tokens.padding.medium * 2
    cLayer: 2

    indicator.anchors.verticalCenter: verticalCenter
    indicator.anchors.right: right
    indicator.anchors.rightMargin: Tokens.padding.large

    onPressed: stateLayer.press(stateLayer.mouseX, stateLayer.mouseY)

    background: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
        topLeftRadius: root.first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
        topRightRadius: root.first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
        bottomLeftRadius: root.last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
        bottomRightRadius: root.last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

        StateLayer {
            id: stateLayer

            manualPressOverride: root.pressed

            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
        }
    }

    contentItem: Item {
        anchors.left: parent.left
        anchors.right: root.indicator.left
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.spacing.medium

        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right

                text: root.text
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right

                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
