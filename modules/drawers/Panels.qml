import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import qs.modules.utilities.toasts as Toasts
import qs.modules.sidebar as Sidebar
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property Item bar

    readonly property alias osd: osd
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popouts
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar
    readonly property alias clearAllButton: clearAllButton

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth

    Osd.Wrapper {
        id: osd

        clip: session.width > 0 || sidebar.width > 0
        screen: root.screen
        visibilities: root.visibilities

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: session.width + sidebar.width
    }

    Notifications.Wrapper {
        id: notifications

        visibilities: root.visibilities
        panels: root

        anchors.top: parent.top
        anchors.right: parent.right
    }

    // Clear all notifications button - positioned to the left of the notification panel
    Item {
        id: clearAllButton

        readonly property bool hasNotifications: Notifs.notClosed.length > 0
        readonly property bool panelVisible: notifications.height > 0 || notifications.implicitHeight > 0
        readonly property bool shouldShow: hasNotifications && panelVisible

        anchors.top: notifications.top
        anchors.right: notifications.left
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.large

        width: button.implicitWidth
        height: button.implicitHeight
        enabled: shouldShow

        IconButton {
            id: button

            icon: "clear_all"
            radius: Appearance.rounding.normal
            padding: Appearance.padding.normal
            font.pointSize: Math.round(Appearance.font.size.large * 1.2)

            onClicked: {
                // Clear all notifications
                for (const notif of Notifs.list.slice())
                    notif.close();
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: button.stateLayer.containsMouse ? 4 : 3
            }
        }

        // Keep notification panel visible when hovering over the button
        MouseArea {
            anchors.fill: button
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                if (notifications.content && Notifs.notClosed.length > 0) {
                    notifications.content.show();
                }
            }
            onExited: {
                // Panel will be hidden by Interactions.qml if mouse is not over panel or button
            }
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        opacity: shouldShow ? 1 : 0
        scale: shouldShow ? 1 : 0.5
    }

    Notifications.NotificationToasts {
        id: notificationToasts

        panels: root

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Config.border.thickness
        anchors.rightMargin: Config.border.thickness
    }

    Session.Wrapper {
        id: session

        clip: sidebar.width > 0
        visibilities: root.visibilities
        panels: root

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebar.width
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        visibilities: root.visibilities
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Dashboard.Wrapper {
        id: dashboard

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    BarPopouts.Wrapper {
        id: popouts

        screen: root.screen

        x: isDetached ? (root.width - nonAnimWidth) / 2 : 0
        y: {
            if (isDetached)
                return (root.height - nonAnimHeight) / 2;

            const off = currentCenter - Config.border.thickness - nonAnimHeight / 2;
            const diff = root.height - Math.floor(off + nonAnimHeight);
            if (diff < 0)
                return off + diff;
            return Math.max(off, 0);
        }
    }

    Utilities.Wrapper {
        id: utilities

        visibilities: root.visibilities
        sidebar: sidebar

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top
        anchors.right: sidebar.left
        anchors.margins: Appearance.padding.normal
    }

    Sidebar.Wrapper {
        id: sidebar

        visibilities: root.visibilities
        panels: root

        anchors.top: notifications.bottom
        anchors.bottom: utilities.top
        anchors.right: parent.right
    }
}
