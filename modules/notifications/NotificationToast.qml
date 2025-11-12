import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Notifs.Notif modelData

    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Appearance.padding.smaller * 2

    radius: Appearance.rounding.normal
    color: Colours.palette.m3surface

    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.smaller
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        Item {
            Layout.preferredWidth: Config.notifs.sizes.image
            Layout.preferredHeight: Config.notifs.sizes.image

            Loader {
                id: imageLoader

                active: root.hasImage
                asynchronous: true
                anchors.fill: parent

                sourceComponent: ClippingRectangle {
                    radius: Appearance.rounding.full
                    implicitWidth: Config.notifs.sizes.image
                    implicitHeight: Config.notifs.sizes.image

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl(root.modelData.image)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                    }
                }
            }

            Loader {
                id: appIconLoader

                active: root.hasAppIcon || !root.hasImage
                asynchronous: true

                anchors.horizontalCenter: root.hasImage ? undefined : parent.horizontalCenter
                anchors.verticalCenter: root.hasImage ? undefined : parent.verticalCenter
                anchors.right: root.hasImage ? parent.right : undefined
                anchors.bottom: root.hasImage ? parent.bottom : undefined

                sourceComponent: StyledRect {
                    radius: Appearance.rounding.full
                    color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3error : root.modelData.urgency === NotificationUrgency.Low ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : Colours.palette.m3secondaryContainer
                    implicitWidth: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image
                    implicitHeight: root.hasImage ? Config.notifs.sizes.badge : Config.notifs.sizes.image

                    Loader {
                        id: appIcon

                        active: root.hasAppIcon
                        asynchronous: true

                        anchors.centerIn: parent

                        width: Math.round(parent.width * 0.6)
                        height: Math.round(parent.width * 0.6)

                        sourceComponent: ColouredIcon {
                            anchors.fill: parent
                            source: Quickshell.iconPath(root.modelData.appIcon)
                            colour: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.modelData.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                            layer.enabled: root.modelData.appIcon.endsWith("symbolic")
                        }
                    }

                    Loader {
                        active: !root.hasAppIcon
                        asynchronous: true
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -Appearance.font.size.large * 0.02
                        anchors.verticalCenterOffset: Appearance.font.size.large * 0.02

                        sourceComponent: MaterialIcon {
                            text: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency)
                            color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3onError : root.modelData.urgency === NotificationUrgency.Low ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: root.modelData.summary
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: root.modelData.body
                color: Colours.palette.m3onSurface
                opacity: 0.8
                elide: Text.ElideRight
            }
        }
    }

    Behavior on border.color {
        CAnim {}
    }
}
