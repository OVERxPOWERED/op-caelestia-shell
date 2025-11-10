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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            spacing: Appearance.spacing.small

            RowLayout {
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

            StyledText {
                text: qsTr("Output devices (%1)").arg(Audio.sinks.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                text: qsTr("All available output devices")
                color: Colours.palette.m3outline
            }

            StyledListView {
                id: outputView

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: Audio.sinks
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: outputView
                }

                delegate: StyledRect {
                    required property var modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Audio.sink?.id === modelData.id ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: Audio.sink?.id === modelData.id ? 1 : 0
                    border.color: Colours.palette.m3primary

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

                            text: modelData.description || qsTr("Unknown")
                            font.weight: Audio.sink?.id === modelData.id ? 500 : 400
                        }
                    }

                    implicitHeight: outputRowLayout.implicitHeight + Appearance.padding.normal * 2
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Input devices (%1)").arg(Audio.sources.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                text: qsTr("All available input devices")
                color: Colours.palette.m3outline
            }

            StyledListView {
                id: inputView

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: Audio.sources
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: inputView
                }

                delegate: StyledRect {
                    required property var modelData

                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Audio.source?.id === modelData.id ? Colours.tPalette.m3surfaceContainer.a : 0)
                    radius: Appearance.rounding.normal
                    border.width: Audio.source?.id === modelData.id ? 1 : 0
                    border.color: Colours.palette.m3primary

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
                            text: Audio.source?.id === modelData.id ? "mic" : "mic_external_on"
                            font.pointSize: Appearance.font.size.large
                            fill: Audio.source?.id === modelData.id ? 1 : 0
                        }

                        StyledText {
                            Layout.fillWidth: true

                            text: modelData.description || qsTr("Unknown")
                            font.weight: Audio.source?.id === modelData.id ? 500 : 400
                        }
                    }

                    implicitHeight: inputRowLayout.implicitHeight + Appearance.padding.normal * 2
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2

            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "volume_up"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Audio settings")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Output volume")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            RowLayout {
                spacing: Appearance.spacing.smaller

                StyledText {
                    text: qsTr("Volume")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
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
                        text: Audio.muted ? "volume_off" : "volume_up"
                        color: Audio.muted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    }
                }
            }

            StyledText {
                text: Audio.muted ? qsTr("Muted") : qsTr("%1%").arg(Math.round(Audio.volume * 100))
                color: Audio.muted ? Colours.palette.m3primary : Colours.palette.m3outline
            }

            StyledSlider {
                Layout.fillWidth: true
                implicitHeight: Appearance.padding.normal * 3

                value: Audio.volume
                enabled: !Audio.muted
                opacity: enabled ? 1 : 0.5
                onMoved: Audio.setVolume(value)
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Input volume")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            RowLayout {
                spacing: Appearance.spacing.smaller

                StyledText {
                    text: qsTr("Volume")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
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
                        text: Audio.sourceMuted ? "mic_off" : "mic"
                        color: Audio.sourceMuted ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    }
                }
            }

            StyledText {
                text: Audio.sourceMuted ? qsTr("Muted") : qsTr("%1%").arg(Math.round(Audio.sourceVolume * 100))
                color: Audio.sourceMuted ? Colours.palette.m3primary : Colours.palette.m3outline
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

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}


