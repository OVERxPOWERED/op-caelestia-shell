import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Voice typing")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Status & Control
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
                        : Tr.tr("Ready to dictate")
            value: VoiceTyping.isListening
                ? Tr.tr("Listening")
                : VoiceTyping.isPaused
                    ? Tr.tr("Paused")
                    : VoiceTyping.isTranscribing
                        ? Tr.tr("Transcribing")
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

        // Engine & Models
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

        // Floating Pill
        SectionHeader {
            text: Tr.tr("Floating pill")
        }

        InfoRow {
            first: true
            icon: "open_with"
            label: Tr.tr("Pill position")
            subtext: VoiceTyping.customPosition
                ? Tr.tr("Custom coordinates on screen (drag pill to reposition)")
                : Tr.tr("Default position centered in the top bar")
            value: VoiceTyping.customPosition
                ? `${VoiceTyping.pillX}, ${VoiceTyping.pillY}`
                : Tr.tr("Centered")
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset pill position")
            subtext: Tr.tr("Reset pill back to default top-center alignment")
            disabled: !VoiceTyping.customPosition
            onClicked: VoiceTyping.resetPosition()
        }

        // Formatting & Commands
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
}
