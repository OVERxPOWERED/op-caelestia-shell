import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

StyledRect {
    id: root

    required property Notifs.Notif modelData
    required property bool hasImage
    required property bool hasAppIcon
    required property bool isCritical
    required property bool isLow

    radius: Appearance.rounding.full
    color: {
        if (root.isCritical) return Colours.palette.m3error;
        if (root.isLow) return Colours.layer(Colours.palette.m3surfaceContainerHighest, 2);
        return Colours.palette.m3secondaryContainer;
    }
    implicitWidth: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image
    implicitHeight: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image

    Loader {
        id: icon

        active: root.hasAppIcon
        asynchronous: false
        visible: active

        anchors.centerIn: parent

        width: Math.round(parent.width * 0.6)
        height: Math.round(parent.width * 0.6)

        sourceComponent: ColouredIcon {
            anchors.fill: parent
            source: Quickshell.iconPath(root.modelData.appIcon)
            colour: {
                if (root.isCritical) return Colours.palette.m3onError;
                if (root.isLow) return Colours.palette.m3onSurface;
                return Colours.palette.m3onSecondaryContainer;
            }
            layer.enabled: root.modelData.appIcon.endsWith("symbolic")
        }
    }

    Loader {
        active: !root.hasAppIcon
        asynchronous: false
        visible: active
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -Appearance.font.size.large * 0.02
        anchors.verticalCenterOffset: Appearance.font.size.large * 0.02

        sourceComponent: MaterialIcon {
            text: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency)

            color: {
                if (root.isCritical) return Colours.palette.m3onError;
                if (root.isLow) return Colours.palette.m3onSurface;
                return Colours.palette.m3onSecondaryContainer;
            }
            font.pointSize: Appearance.font.size.large
        }
    }
}

