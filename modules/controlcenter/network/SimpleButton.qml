import qs.components
import qs.components.effects
import qs.config
import QtQuick

StyledRect {
    id: root

    property color onColor: Colours.palette.m3onSurface
    property alias disabled: stateLayer.disabled
    property alias text: label.text
    property alias enabled: stateLayer.enabled

    implicitWidth: label.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: label.implicitHeight + Appearance.padding.normal * 2
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

    StyledText {
        id: label
        anchors.centerIn: parent
        color: parent.onColor
    }

    signal clicked
}

