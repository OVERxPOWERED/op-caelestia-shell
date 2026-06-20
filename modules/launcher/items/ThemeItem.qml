import QtQuick
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ThemeManager.Theme modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        StyledClippingRect {
            id: preview

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8
            radius: Tokens.rounding.medium

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.tPalette.m3outline
                fontStyle: Tokens.font.icon.extraLarge
            }

            CachingImage {
                anchors.fill: parent
                path: root.modelData?.wallpaperPath ?? ""
            }
        }

        Column {
            anchors.left: preview.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - preview.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.medium : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                text: root.modelData?.folder ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            asynchronous: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: GlobalConfig.paths.themeName === root.modelData?.folder

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.large
            }
        }
    }
}
