import "media"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property bool needsKeyboard: false // TODO

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        CoverVisualiser {
            Layout.fillHeight: true
            implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
        }

        Details {
            Layout.fillWidth: true
        }

        LyricsAndSelector {
            Layout.fillHeight: true
            implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
        }
    }
}
