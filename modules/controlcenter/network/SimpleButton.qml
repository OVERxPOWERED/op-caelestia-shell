import qs.components
import qs.components.controls
import qs.components.effects
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property color onColor: Colours.palette.m3onSurface
    property alias disabled: stateLayer.disabled
    property alias text: label.text
    property alias enabled: stateLayer.enabled
    property string icon: ""

    implicitWidth: rowLayout.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: rowLayout.implicitHeight + Appearance.padding.small
    radius: Appearance.rounding.normal

    StateLayer {
        id: stateLayer
        color: parent.onColor
        function onClicked(): void {
            if (parent.enabled !== false) {
                parent.clicked();
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            id: iconItem
            visible: root.icon.length > 0
            text: root.icon
            color: root.onColor
            font.pointSize: Appearance.font.size.large
        }

        StyledText {
            id: label
            Layout.leftMargin: root.icon.length > 0 ? Appearance.padding.smaller : 0
            color: parent.parent.onColor
        }
    }

    signal clicked
}