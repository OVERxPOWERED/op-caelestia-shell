pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.modules.nexus.common
import qs.modules.voice
import qs.services

PageBase {
    id: root

    title: Tr.tr("Voice typing")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // =========================================================================
        // Status & Control
        // =========================================================================
        SectionHeader {
            first: true
            text: Tr.tr("Status & Control")
        }

        InfoRow {
            first: true
            icon: "mic"
            iconColour: VoiceTyping.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            label: Tr.tr("Engine state")
            subtext: VoiceTyping.isListening
                ? Tr.tr("Listening for speech...")
                : VoiceTyping.isPaused
                    ? Tr.tr("Temporarily paused")
                    : VoiceTyping.isTranscribing
                        ? Tr.tr("Transcribing speech...")
                        : VoiceTyping.isDone
                            ? Tr.tr("Dictation inserted")
                            : Tr.tr("Ready to dictate")
            value: VoiceTyping.isListening
                ? Tr.tr("Listening")
                : VoiceTyping.isPaused
                    ? Tr.tr("Paused")
                    : VoiceTyping.isTranscribing
                        ? Tr.tr("Transcribing")
                        : VoiceTyping.isDone
                            ? Tr.tr("Done")
                            : Tr.tr("Idle")
        }

        InfoRow {
            icon: "keyboard"
            label: Tr.tr("Keyboard shortcut")
            subtext: Tr.tr("Global keybind to toggle voice typing anywhere")
            value: "Super + Shift + V"
        }

        RowButton {
            last: true
            icon: VoiceTyping.active ? "stop" : "mic"
            text: VoiceTyping.active ? Tr.tr("Stop voice typing") : Tr.tr("Start voice typing")
            subtext: VoiceTyping.active
                ? Tr.tr("Click to stop recording and close the floating pill")
                : Tr.tr("Click to summon the pill and dictate into the focused window")
            onClicked: VoiceTyping.toggle()
        }

        // =========================================================================
        // Appearance / Theme
        // =========================================================================
        SectionHeader {
            text: Tr.tr("Appearance / Theme")
        }

        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: themeGrid.implicitHeight + Tokens.padding.medium * 2

            GridLayout {
                id: themeGrid

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                columns: 2
                columnSpacing: Tokens.spacing.small
                rowSpacing: Tokens.spacing.small

                ThemeCard {
                    Layout.fillWidth: true
                    themeId: "classic"
                    title: Tr.tr("Default · Classic")
                    subtitle: Tr.tr("Two-line recording pill")
                    selected: VoiceTyping.theme === "classic"
                    onClicked: VoiceTyping.setTheme("classic")
                }

                ThemeCard {
                    Layout.fillWidth: true
                    themeId: "compact"
                    title: Tr.tr("Compact")
                    subtitle: Tr.tr("Single-row recording pill")
                    selected: VoiceTyping.theme === "compact"
                    onClicked: VoiceTyping.setTheme("compact")
                }

                ThemeCard {
                    Layout.fillWidth: true
                    themeId: "wave"
                    title: Tr.tr("Dynamic Wave")
                    subtitle: Tr.tr("Floating audio ribbons")
                    selected: VoiceTyping.theme === "wave"
                    onClicked: VoiceTyping.setTheme("wave")
                }
            }
        }

        SelectRow {
            id: posPresetRow

            label: Tr.tr("Position on active monitor")
            subtext: VoiceTyping.customPosition
                ? Tr.tr("Custom dragged position (%1, %2)").arg(VoiceTyping.pillX).arg(VoiceTyping.pillY)
                : Tr.tr("Aligned relative to the active monitor")
            fallbackText: Tr.tr("Custom")
            menuItems: posPresetItems.instances
            onSelected: item => VoiceTyping.setPositionPreset(item.value)

            Binding {
                target: posPresetRow
                property: "active"
                value: posPresetItems.instances.find(i => i.value === VoiceTyping.positionPreset) ?? null
            }

            Variants {
                id: posPresetItems

                model: [
                    { id: "top-center", name: Tr.tr("Top center") },
                    { id: "bottom-center", name: Tr.tr("Bottom center") },
                    { id: "top-left", name: Tr.tr("Top left") },
                    { id: "top-right", name: Tr.tr("Top right") },
                    { id: "bottom-left", name: Tr.tr("Bottom left") },
                    { id: "bottom-right", name: Tr.tr("Bottom right") }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            id: scaleRow

            label: Tr.tr("Widget scale (%)")
            subtext: Tr.tr("Scale the floating voice typing widget")
            from: 75
            to: 150
            stepSize: 5
            onMoved: v => VoiceTyping.setWidgetScale(v)

            Binding {
                target: scaleRow
                property: "value"
                value: VoiceTyping.widgetScale
            }
        }

        StepperRow {
            id: speedRow

            label: Tr.tr("Animation speed (%)")
            subtext: Tr.tr("Adjust waveform and transition speed")
            from: 50
            to: 200
            stepSize: 10
            onMoved: v => VoiceTyping.setAnimationSpeed(v)

            Binding {
                target: speedRow
                property: "value"
                value: VoiceTyping.animationSpeed
            }
        }

        ToggleRow {
            text: Tr.tr("Enable animations")
            subtext: Tr.tr("Animate transitions, ribbons, and reactive waveforms")
            checked: VoiceTyping.enableAnimations
            onToggled: VoiceTyping.setEnableAnimations(checked)
        }

        ToggleRow {
            text: Tr.tr("Transcription preview")
            subtext: Tr.tr("Applies to the selected theme")
            checked: VoiceTyping.transcriptionPreview
            onToggled: VoiceTyping.setTranscriptionPreview(checked)
        }

        ToggleRow {
            text: Tr.tr("Live waveform")
            subtext: Tr.tr("Show real-time audio visualization while listening")
            checked: VoiceTyping.liveWaveform
            onToggled: VoiceTyping.setLiveWaveform(checked)
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset pill position")
            subtext: Tr.tr("Reset pill back to default top-center alignment")
            disabled: !VoiceTyping.customPosition && VoiceTyping.positionPreset === "top-center"
            onClicked: VoiceTyping.resetPosition()
        }

        // =========================================================================
        // AI Models & Service
        // =========================================================================
        SectionHeader {
            text: Tr.tr("AI Models & Service")
        }

        InfoRow {
            first: true
            icon: "memory"
            label: Tr.tr("Whisper service")
            subtext: Tr.tr("Local whisper.cpp acceleration server")
            value: "127.0.0.1:8089"
        }

        InfoRow {
            icon: "graphic_eq"
            label: Tr.tr("Speech recognition model")
            subtext: Tr.tr("Whisper base model optimized for English dictation")
            value: "ggml-base.en.bin"
        }

        InfoRow {
            last: true
            icon: "record_voice_over"
            label: Tr.tr("Voice activity detection")
            subtext: Tr.tr("Silero deep-learning neural network for silence filtering")
            value: "Silero VAD ONNX"
        }

        // =========================================================================
        // Smart Formatting
        // =========================================================================
        SectionHeader {
            text: Tr.tr("Smart formatting")
        }

        InfoRow {
            first: true
            icon: "format_quote"
            label: Tr.tr("Spoken punctuation")
            subtext: Tr.tr("Say 'period', 'comma', 'question mark', 'colon', 'dash'")
            value: Tr.tr("Active")
        }

        InfoRow {
            icon: "keyboard_return"
            label: Tr.tr("Spoken newlines")
            subtext: Tr.tr("Say 'new line' or 'new paragraph' to insert line breaks")
            value: Tr.tr("Active")
        }

        InfoRow {
            icon: "format_size"
            label: Tr.tr("Sentence capitalization")
            subtext: Tr.tr("Automatically capitalizes the first word of each sentence")
            value: Tr.tr("Active")
        }

        InfoRow {
            last: true
            icon: "undo"
            label: Tr.tr("Spoken undo")
            subtext: Tr.tr("Say 'undo' to revert the most recent dictated phrase")
            value: Tr.tr("Active")
        }
    }

    component ThemeCard: StyledRect {
        id: card

        required property string themeId
        required property string title
        required property string subtitle
        required property bool selected

        signal clicked()

        implicitHeight: cardCol.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: selected
            ? Qt.alpha(Colours.palette.m3primaryContainer, 0.35)
            : Colours.tPalette.m3surfaceContainerHigh
        border.width: selected ? 1.5 : 1
        border.color: selected
            ? Colours.palette.m3primary
            : Qt.alpha(Colours.palette.m3outlineVariant, 0.4)

        Behavior on color {
            CAnim {}
        }

        Behavior on border.color {
            CAnim {}
        }

        StateLayer {
            radius: card.radius
            onClicked: card.clicked()
        }

        ColumnLayout {
            id: cardCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            // Visual preview area
            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerLowest
                clip: true

                // Classic preview
                StyledRect {
                    visible: card.themeId === "classic"
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 20, 210)
                    height: 40
                    radius: height / 2
                    color: Qt.alpha(Colours.palette.m3surface, 0.85)

                    GlassRim {
                        z: 10
                        radius: parent.radius
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        StyledRect {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: width / 2
                            color: Qt.alpha(Colours.palette.m3primary, 0.24)

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "mic"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.small
                                scale: 0.75
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                spacing: 4
                                Rectangle {
                                    Layout.preferredWidth: 4
                                    Layout.preferredHeight: 4
                                    radius: 2
                                    color: Colours.palette.m3primary
                                }
                                Text {
                                    text: Tr.tr("Listening")
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Colours.palette.m3onSurface
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Tr.tr("Your words, as you speak")
                                font.pixelSize: 8
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        VoiceDotWave {
                            dotCount: 7
                            inCapsule: true
                            previewMode: true
                            dotSize: 2
                            dotSpacing: 2
                            maxDotHeight: 9
                            implicitHeight: 18
                        }
                    }
                }

                // Compact preview
                StyledRect {
                    visible: card.themeId === "compact"
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, 195)
                    height: 28
                    radius: height / 2
                    color: Qt.alpha(Colours.palette.m3surface, 0.85)

                    GlassRim {
                        z: 10
                        radius: parent.radius
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        MaterialIcon {
                            text: "mic"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                            scale: 0.72
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Tr.tr("Your words, as you speak")
                            font.pixelSize: 9
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        VoiceDotWave {
                            dotCount: 5
                            inCapsule: false
                            previewMode: true
                            dotSize: 2
                            dotSpacing: 2
                            maxDotHeight: 8
                        }
                    }
                }

                // Dynamic Wave preview
                Item {
                    visible: card.themeId === "wave"
                    anchors.fill: parent

                    VoiceWaveCanvas {
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width - 12, 220)
                        height: 36
                        previewMode: true
                        centerHoleRadius: 12
                    }

                    StyledRect {
                        anchors.top: parent.top
                        anchors.topMargin: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 22
                        height: 22
                        radius: width / 2
                        color: Colours.palette.m3surface

                        GlassRim {
                            z: 10
                            radius: parent.radius
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "mic"
                            color: Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.small
                            scale: 0.72
                        }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Tr.tr("Your words, as you speak")
                        font.pixelSize: 9
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            // Card label & selected badge
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: card.title
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: card.subtitle
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    visible: card.selected
                    text: "check_circle"
                    fill: 1
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
