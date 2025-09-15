import ".."
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    enum Type {
        Filled,
        Tonal,
        Text
    }

    property alias icon: label.text
    property bool checked
    property bool toggle
    property real padding: type === IconButton.Text ? Appearance.padding.small / 2 : Appearance.padding.smaller
    property alias font: label.font
    property int type: IconButton.Filled

    property alias stateLayer: stateLayer
    property alias label: label

    property bool internalChecked
    property color activeColour: type === IconButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    property color inactiveColour: {
        if (!toggle && type === IconButton.Filled)
            return Colours.palette.m3primary;
        return type === IconButton.Filled ? Colours.palette.m3surfaceContainer : Colours.palette.m3secondaryContainer;
    }
    property color activeOnColour: type === IconButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondary
    property color inactiveOnColour: {
        if (!toggle && type === IconButton.Filled)
            return Colours.palette.m3onPrimary;
        return type === IconButton.Filled ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSecondaryContainer;
    }

    signal clicked

    onCheckedChanged: internalChecked = checked

    radius: internalChecked ? Appearance.rounding.small : implicitHeight / 2
    color: type === IconButton.Text ? "transparent" : internalChecked ? activeColour : inactiveColour

    implicitWidth: implicitHeight
    implicitHeight: label.implicitHeight + padding * 2

    StateLayer {
        id: stateLayer

        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour

        function onClicked(): void {
            if (root.toggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        fill: !root.toggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {}
        }
    }

    Behavior on radius {
        Anim {}
    }
}
