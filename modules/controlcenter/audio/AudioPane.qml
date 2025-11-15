pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
            flickableDirection: Flickable.VerticalFlick
            contentHeight: leftContent.height
            clip: true

            ColumnLayout {
                id: leftContent

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Appearance.spacing.normal

                // Settings header above the collapsible sections
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Settings")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                CollapsibleSection {
                    id: outputDevicesSection

                    Layout.fillWidth: true
                    title: qsTr("Output devices")
                    expanded: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Devices (%1)").arg(Audio.sinks.length)
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("All available output devices")
                            color: Colours.palette.m3outline
                        }

                        Repeater {
                            Layout.fillWidth: true
                            model: Audio.sinks

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Audio.sink?.id === modelData.id ? Colours.tPalette.m3surfaceContainer.a : 0)
                                radius: Appearance.rounding.normal

                                StateLayer {
                                    function onClicked(): void {
                                        Audio.setAudioSink(modelData);
                                    }
                                }

                                RowLayout {
                                    id: outputRowLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    MaterialIcon {
                                        text: Audio.sink?.id === modelData.id ? "speaker" : "speaker_group"
                                        font.pointSize: Appearance.font.size.large
                                        fill: Audio.sink?.id === modelData.id ? 1 : 0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1

                                        text: modelData.description || qsTr("Unknown")
                                        font.weight: Audio.sink?.id === modelData.id ? 500 : 400
                                    }
                                }

                                implicitHeight: outputRowLayout.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }

                CollapsibleSection {
                    id: inputDevicesSection

                    Layout.fillWidth: true
                    title: qsTr("Input devices")
                    expanded: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Devices (%1)").arg(Audio.sources.length)
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("All available input devices")
                            color: Colours.palette.m3outline
                        }

                        Repeater {
                            Layout.fillWidth: true
                            model: Audio.sources

                            delegate: StyledRect {
                                required property var modelData

                                Layout.fillWidth: true

                                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Audio.source?.id === modelData.id ? Colours.tPalette.m3surfaceContainer.a : 0)
                                radius: Appearance.rounding.normal

                                StateLayer {
                                    function onClicked(): void {
                                        Audio.setAudioSource(modelData);
                                    }
                                }

                                RowLayout {
                                    id: inputRowLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Appearance.padding.normal

                                    spacing: Appearance.spacing.normal

                                    MaterialIcon {
                                        text: "mic"
                                        font.pointSize: Appearance.font.size.large
                                        fill: Audio.source?.id === modelData.id ? 1 : 0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1

                                        text: modelData.description || qsTr("Unknown")
                                        font.weight: Audio.source?.id === modelData.id ? 500 : 400
                                    }
                                }

                                implicitHeight: inputRowLayout.implicitHeight + Appearance.padding.normal * 2
                            }
                        }
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledFlickable {
            id: rightFlickable

            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2

            flickableDirection: Flickable.VerticalFlick
            contentHeight: contentLayout.implicitHeight
            clip: true

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: rightFlickable
            }

            ColumnLayout {
                id: contentLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Appearance.spacing.normal

                ConnectionHeader {
                    icon: "volume_up"
                    title: qsTr("Audio Settings")
                }

                SectionHeader {
                    title: qsTr("Output volume")
                    description: qsTr("Control the volume of your output device")
                }

                SectionContainer {
                    contentSpacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Volume")
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: Audio.muted ? qsTr("Muted") : qsTr("%1%").arg(Math.round(Audio.volume * 100))
                                color: Audio.muted ? Colours.palette.m3primary : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: muteIcon.implicitHeight + Appearance.padding.normal * 2

                                radius: Appearance.rounding.normal
                                color: Audio.muted ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                                StateLayer {
                                    function onClicked(): void {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.muted = !Audio.sink.audio.muted;
                                        }
                                    }
                                }

                                MaterialIcon {
                                    id: muteIcon

                                    anchors.centerIn: parent
                                    text: Audio.muted ? "volume_off" : "volume_mute"
                                    color: Audio.muted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.normal * 3

                            value: Audio.volume
                            enabled: !Audio.muted
                            opacity: enabled ? 1 : 0.5
                            onMoved: Audio.setVolume(value)
                        }
                    }
                }

                SectionHeader {
                    title: qsTr("Input volume")
                    description: qsTr("Control the volume of your input device")
                }

                SectionContainer {
                    contentSpacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Volume")
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: Audio.sourceMuted ? qsTr("Muted") : qsTr("%1%").arg(Math.round(Audio.sourceVolume * 100))
                                color: Audio.sourceMuted ? Colours.palette.m3primary : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                            }

                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: muteInputIcon.implicitHeight + Appearance.padding.normal * 2

                                radius: Appearance.rounding.normal
                                color: Audio.sourceMuted ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                                StateLayer {
                                    function onClicked(): void {
                                        if (Audio.source?.audio) {
                                            Audio.source.audio.muted = !Audio.source.audio.muted;
                                        }
                                    }
                                }

                                MaterialIcon {
                                    id: muteInputIcon

                                    anchors.centerIn: parent
                                    text: "mic_off"
                                    color: Audio.sourceMuted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.normal * 3

                            value: Audio.sourceVolume
                            enabled: !Audio.sourceMuted
                            opacity: enabled ? 1 : 0.5
                            onMoved: Audio.setSourceVolume(value)
                        }
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}