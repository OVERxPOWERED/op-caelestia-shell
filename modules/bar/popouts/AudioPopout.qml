pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property list<PwNode> activeStreams: [...(Audio.streams ?? [])]
        .filter(s => s && !Audio.isHiddenStream(s))
        .sort((a, b) => (Audio.getStreamName(a) || "").localeCompare(Audio.getStreamName(b) || ""))

    implicitWidth: 340
    spacing: Tokens.spacing.medium

    function getStreamIconSource(stream: PwNode): string {
        const icon = Audio.getStreamIcon(stream);
        if (icon)
            return icon;
        return Quickshell.iconPath("audio-x-generic");
    }

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.leftMargin: Tokens.padding.small
        text: Tr.tr("Audio")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            // Output devices card
            StyledRect {
                Layout.fillWidth: true
                implicitWidth: outputLayout.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: outputLayout.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                GlassRim {
                    z: 10
                    radius: parent.radius
                }

                ColumnLayout {
                    id: outputLayout

                    width: parent.width - Tokens.padding.medium * 2
                    x: Tokens.padding.medium
                    y: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: Tr.trCtx("Output device", "audio output device")
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    }

                    StyledText {
                        visible: Audio.sinks.length === 0
                        Layout.fillWidth: true
                        text: Tr.tr("No output devices connected")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    Repeater {
                        model: Audio.sinks

                        StyledRadioButton {
                            required property PwNode modelData

                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            ButtonGroup.group: sinks
                            checked: Audio.sink?.id === modelData.id
                            onClicked: Audio.setAudioSink(modelData)
                            text: modelData.description || modelData.name
                        }
                    }
                }
            }

            // Input devices card
            StyledRect {
                Layout.fillWidth: true
                implicitWidth: inputLayout.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: inputLayout.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                GlassRim {
                    z: 10
                    radius: parent.radius
                }

                ColumnLayout {
                    id: inputLayout

                    width: parent.width - Tokens.padding.medium * 2
                    x: Tokens.padding.medium
                    y: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: Tr.trCtx("Input device", "audio input device")
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    }

                    StyledText {
                        visible: Audio.sources.length === 0
                        Layout.fillWidth: true
                        text: Tr.tr("No input devices connected")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    Repeater {
                        model: Audio.sources

                        StyledRadioButton {
                            required property PwNode modelData

                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            ButtonGroup.group: sources
                            checked: Audio.source?.id === modelData.id
                            onClicked: Audio.setAudioSource(modelData)
                            text: modelData.description || modelData.name
                        }
                    }
                }
            }
        }

        // Master vertical volume slider
        CustomMouseArea {
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.sizes.osd.sliderWidth
            implicitWidth: Tokens.sizes.osd.sliderWidth
            acceptedButtons: Qt.NoButton

            function onWheel(event: WheelEvent): void {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            FilledSlider {
                anchors.fill: parent

                icon: Icons.getVolumeIcon(value, Audio.muted)
                value: Audio.volume
                to: GlobalConfig.services.maxVolume
                enableIconTap: true

                onIconTapped: Audio.setStreamMuted(Audio.sink, !Audio.muted)
                onMoved: Audio.setVolume(value)
            }
        }
    }

    // Multi-app volume card with fade-scroll indicator (no scrollbar)
    StyledRect {
        id: appsCard

        // Fit 3 full rows + peek of 4th row before scrolling so overflow fade is clear
        readonly property real rowHeight: Math.max(24, Tokens.padding.medium * 2)
        readonly property real maxListHeight: rowHeight * 3 + Tokens.spacing.medium * 2.5

        Layout.fillWidth: true
        visible: streamRepeater.count > 0
        implicitWidth: appLayout.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: Math.min(appLayout.implicitHeight, maxListHeight) + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        GlassRim {
            z: 10
            radius: parent.radius
        }

        VerticalFadeFlickable {
            id: appFlickable

            readonly property bool scrollable: contentHeight > height

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            fadeAmount: scrollable ? 0.18 : 0
            interactive: scrollable
            contentWidth: width
            contentHeight: appLayout.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: appLayout

                width: appFlickable.width
                spacing: Tokens.spacing.medium

                Repeater {
                    id: streamRepeater

                    model: root.activeStreams

                    RowLayout {
                        id: streamRow

                        required property PwNode modelData
                        required property int index

                        readonly property real streamVol: Audio.getStreamVolume(modelData)
                        readonly property bool streamMuted: Audio.getStreamMuted(modelData)

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        ColouredIcon {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: root.getStreamIconSource(streamRow.modelData)
                            colour: Colours.palette.m3secondary
                            layer.enabled: Config.bar.tray.recolour
                            opacity: streamRow.streamMuted ? 0.38 : 1.0

                            TapHandler {
                                onTapped: Audio.setStreamMuted(streamRow.modelData, !streamRow.streamMuted)
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Tokens.padding.medium * 2

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: event => {
                                    if (appFlickable.scrollable && !(event.modifiers & Qt.ShiftModifier)) {
                                        event.accepted = false;
                                        return;
                                    }
                                    const step = GlobalConfig.services.audioIncrement;
                                    const cur = streamRow.streamVol;
                                    if (event.angleDelta.y > 0)
                                        Audio.setStreamVolume(streamRow.modelData, Math.min(GlobalConfig.services.maxVolume, cur + step));
                                    else if (event.angleDelta.y < 0)
                                        Audio.setStreamVolume(streamRow.modelData, Math.max(0, cur - step));
                                }
                            }

                            StyledSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: parent.implicitHeight

                                radius: Tokens.rounding.small
                                inlineHandle: true
                                value: streamRow.streamVol
                                enabled: !streamRow.streamMuted
                                onInteraction: v => Audio.setStreamVolume(streamRow.modelData, v)
                            }
                        }
                    }
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.small
        text: Tr.tr("Open settings")
        icon: "settings"

        onClicked: root.popouts.detachRequested("audio")
    }
}
