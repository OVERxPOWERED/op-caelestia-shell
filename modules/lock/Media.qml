import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

StyledClippingRect {
    id: root

    required property var lock
    property Item blurSource: null
    property real absX: 0
    property real absY: 0
    property bool borderless: false
    property bool compactLayout: false

    implicitHeight: (compactLayout ? compactRow.implicitHeight : layout.implicitHeight) + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Config.lock.useLegacyLayout ? Colours.tPalette.m3surfaceContainer : "transparent"

    GlassBackdrop {
        visible: !Config.lock.useLegacyLayout && !root.borderless && root.blurSource !== null
        blurSource: root.blurSource
        absX: root.absX
        absY: root.absY
        radius: root.radius
    }

    RowLayout {
        id: compactRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium
        visible: root.compactLayout

        StyledClippingRect {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: Tokens.rounding.medium
            color: Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.6)

            MaterialIcon {
                anchors.centerIn: parent
                text: "music_note"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                visible: artThumb.status !== Image.Ready
            }

            FadeImage {
                id: artThumb

                anchors.fill: parent
                source: Players.getArtUrl(Players.active)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: (Players.active?.trackTitle ?? Tr.tr("Nothing playing")) || Tr.tr("Unknown track")
                color: Colours.palette.m3primary
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: (Players.active?.trackArtist ?? Tr.tr("Try playing some music!")) || Tr.tr("Unknown artist")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Tonal
                icon: "skip_previous"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            IconButton {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                isRound: true
                shapeMorph: true
                checked: Players.active?.isPlaying ?? false
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Tonal
                icon: "skip_next"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall
        visible: !root.compactLayout

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: (Players.active?.trackTitle ?? Tr.tr("Nothing playing")) || Tr.tr("Unknown track")
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font: Tokens.font.title.medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: (Players.active?.trackArtist ?? Tr.tr("Try playing some music!")) || Tr.tr("Unknown artist")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.small

            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Tonal
                icon: "skip_previous"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            IconButton {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                isRound: true
                shapeMorph: true
                checked: Players.active?.isPlaying ?? false
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
                implicitWidth: implicitHeight + Tokens.padding.largeIncreased * 2
            }

            IconButton {
                type: IconButton.Tonal
                icon: "skip_next"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }
    }

    GlassRim {
        z: 10
        visible: !root.borderless
        radius: root.radius
        deepBevel: Config.lock.useLegacyLayout
        dualRim: !Config.lock.useLegacyLayout
    }
}
