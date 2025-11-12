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

                sourceComponent: AppIconBadge {
                    modelData: root.modelData
                    hasImage: root.hasImage
                    hasAppIcon: root.hasAppIcon
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
