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

    radius: Appearance.rounding.full
    color: modelData.getBadgeBackgroundColor()
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
            colour: root.modelData.getIconColor()
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
            color: root.modelData.getIconColor()
            font.pointSize: Appearance.font.size.large
        }
    }
}

