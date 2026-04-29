pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
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

    readonly property real arcCoverGap: Tokens.spacing.extraSmall
    property bool coverHadPrevious

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

    CircularProgress {
        id: prog

        anchors.centerIn: cover
        implicitSize: cover.width + root.arcCoverGap + thickness * 2

        fgColour: Colours.palette.m3primary
        strokeWidth: Tokens.sizes.dashboard.mediaProgressThickness
        startAngle: -90 - sweepAngle / 2
        sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
        value: root.playerProgress

        wavy: true
        waveFrequency: 8
        waveDuration: 2000
        wavePaused: !Players.active?.isPlaying
    }

    Item {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium + root.arcCoverGap + prog.thickness
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
            text: image.status === Image.Error ? "broken_image" : "art_track"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size((parent.width * 0.35) || 1).build()
            opacity: image.status === Image.Null || image.status === Image.Error ? 1 : 0
            animate: true

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            anchors.centerIn: parent
            asynchronous: true
            active: opacity > 0
            opacity: image.status === Image.Loading ? 1 : 0

            sourceComponent: LoadingIndicator {
                implicitSize: cover.width * 0.3
                color: Colours.palette.m3primaryContainer
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Image {
            id: image

            anchors.fill: parent

            source: Players.getArtUrl(Players.active)
            asynchronous: true
            fillMode: Image.PreserveAspectCrop

            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(width * dpr, height * dpr);
            }

            layer.enabled: true
            layer.effect: Mask {
                maskSource: coverShape
            }

            retainWhileLoading: true
            opacity: 0

            onStatusChanged: {
                if (!opacityInAnim.running && image.status === Image.Ready) {
                    opacityInAnim.type = root.coverHadPrevious ? Anim.DefaultEffects : Anim.StandardLarge;
                    opacityInAnim.start();
                }
            }

            Anim on opacity {
                id: opacityInAnim

                running: false
                to: 1
                type: Anim.DefaultEffects
            }

            Behavior on source {
                SequentialAnimation {
                    Anim {
                        target: image
                        property: "opacity"
                        to: 0
                        type: Anim.FastEffects
                    }
                    PropertyAction {
                        target: root
                        property: "coverHadPrevious"
                        value: image.source
                    }
                    PropertyAction {}
                    ScriptAction {
                        script: {
                            if (!opacityInAnim.running && image.status === Image.Ready) {
                                opacityInAnim.type = root.coverHadPrevious ? Anim.DefaultEffects : Anim.StandardLarge;
                                opacityInAnim.start();
                            }
                        }
                    }
                }
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
            checked: Players.active?.isPlaying ?? false
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
