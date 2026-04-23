pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    readonly property real arcCoverGap: Tokens.spacing.small
    readonly property real arcRadius: (cover.width + Tokens.sizes.dashboard.mediaProgressThickness) / 2 + arcCoverGap
    readonly property real arcGap: (Tokens.spacing.extraSmall + Tokens.sizes.dashboard.mediaProgressThickness) / arcRadius * 180 / Math.PI

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.mediaWidth

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer
        opacity: Math.min(1, remainingArc.sweepAngle)

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3secondaryContainer
            strokeWidth: Math.min(1, remainingArc.sweepAngle) * root.Tokens.sizes.dashboard.mediaProgressThickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: remainingArc

                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: -90 - root.Tokens.sizes.dashboard.mediaProgressSweep / 2 + root.playerProgress * root.Tokens.sizes.dashboard.mediaProgressSweep + root.arcGap
                sweepAngle: Math.max(0.1, root.Tokens.sizes.dashboard.mediaProgressSweep * (1 - root.playerProgress) - root.arcGap)
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    WavyLine {
        anchors.fill: cover
        anchors.margins: -lineWidth * amplitudeMultiplier * 2 - lineWidth - root.arcCoverGap

        lineWidth: Tokens.sizes.dashboard.mediaProgressThickness
        color: Colours.palette.m3primary
        pathType: WavyLine.Arc
        radius: root.arcRadius
        frequency: 8
        startAngle: -fullAngle / 2
        fullAngle: Tokens.sizes.dashboard.mediaProgressSweep
        value: root.playerProgress

        Anim on waveProgress {
            running: true
            paused: !Players.active?.isPlaying
            from: 0
            to: 1
            duration: 2000
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        Behavior on color {
            CAnim {}
        }
    }

    Item {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large + Tokens.sizes.dashboard.mediaProgressThickness + root.arcCoverGap
        implicitHeight: width

        // Slight glow to separate from bg
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 1
            shadowColor: Colours.palette.m3outline
            shadowOpacity: 0.3
        }

        Item {
            id: coverShape

            anchors.fill: parent
            layer.enabled: true

            MaterialShape {
                implicitSize: cover.width
                shape: MaterialShape.Cookie12Sided
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                Anim on rotation {
                    running: true
                    paused: !Players.active?.isPlaying
                    from: 360
                    to: 0
                    duration: 23500
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size((parent.width * 0.4) || 1).build()
        }

        Image {
            id: image

            anchors.fill: parent

            source: Players.getArtUrl(Players.active)
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height

            layer.enabled: true
            layer.effect: Mask {
                maskSource: coverShape
            }
        }
    }

    StyledText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.medium

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
        color: Colours.palette.m3primary
        font: Tokens.font.title.small

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
        color: Colours.palette.m3secondary

        width: parent.implicitWidth - Tokens.padding.extraLargeIncreased
        elide: Text.ElideRight
    }

    Item {
        id: controls

        anchors.top: artist.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.medium
        anchors.margins: Tokens.padding.large

        implicitHeight: Math.max(previousBtn.implicitHeight, playPauseBtn.implicitHeight, nextBtn.implicitHeight)

        PlayerControl {
            id: previousBtn

            anchors.left: parent.left
            width: Math.round(implicitWidth * shapeMorphExpansion - playPauseBtn.implicitWidth * (playPauseBtn.shapeMorphExpansion - 1))

            type: IconButton.Tonal
            icon: "skip_previous"
            disabled: !Players.active?.canGoPrevious
            onClicked: Players.active?.previous()
        }

        PlayerControl {
            id: playPauseBtn

            anchors.left: previousBtn.right
            anchors.right: nextBtn.left
            anchors.margins: Tokens.spacing.small

            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            checked: Players.active?.isPlaying
            disabled: !Players.active?.canTogglePlaying
            onClicked: Players.active?.togglePlaying()
        }

        PlayerControl {
            id: nextBtn

            anchors.right: parent.right
            width: Math.round(implicitWidth * shapeMorphExpansion - playPauseBtn.implicitWidth * (playPauseBtn.shapeMorphExpansion - 1))

            type: IconButton.Tonal
            icon: "skip_next"
            disabled: !Players.active?.canGoNext
            onClicked: Players.active?.next()
        }
    }

    AnimatedImage {
        id: bongocat

        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small
        anchors.bottomMargin: Tokens.padding.large
        anchors.margins: Tokens.padding.extraLargeIncreased

        playing: Players.active?.isPlaying ?? false
        speed: Audio.beatTracker.bpm / Config.general.mediaGifSpeedAdjustment // qmllint disable unresolved-type
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    component PlayerControl: IconButton {
        property real shapeMorphExpansion: pressed ? 1.16 : 1

        font: Tokens.font.icon.medium
        isRound: true

        Behavior on shapeMorphExpansion {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }
}
