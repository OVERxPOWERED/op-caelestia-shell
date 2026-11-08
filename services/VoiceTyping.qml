pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    enum State {
        Idle = 0,
        Listening = 1,
        Paused = 2,
        Transcribing = 3,
        Done = 4
    }

    property int state: VoiceTyping.State.Idle
    readonly property bool active: state !== VoiceTyping.State.Idle
    readonly property bool isListening: state === VoiceTyping.State.Listening
    readonly property bool isPaused: state === VoiceTyping.State.Paused
    readonly property bool isTranscribing: state === VoiceTyping.State.Transcribing
    readonly property bool isDone: state === VoiceTyping.State.Done

    property real pillX: -1
    property real pillY: 16
    property bool customPosition: false

    property real audioLevel: 0.0
    property var barLevels: [0.0, 0.0, 0.0, 0.0]
    property real wavePhase: 0.0
    property string liveTranscript: ""
    property string lastCommittedText: ""
    property string transcribedText: ""
    property bool showingCommitPreview: false

    readonly property string statusText: {
        switch (state) {
        case VoiceTyping.State.Listening:
            if (liveTranscript)
                return liveTranscript;
            if (showingCommitPreview && lastCommittedText)
                return lastCommittedText;
            return Tr.tr("Listening");
        case VoiceTyping.State.Paused:
            return Tr.tr("Paused");
        case VoiceTyping.State.Transcribing:
            return liveTranscript ? liveTranscript : Tr.tr("Transcribing");
        default:
            return "";
        }
    }

    signal started()
    signal paused()
    signal resumed()
    signal completed(string text)
    signal cancelled()
    signal pillPositionChanged()

    function savePosition(x: real, y: real): void {
        pillX = Math.round(x);
        pillY = Math.round(y);
        customPosition = true;
        saveState();
        root.pillPositionChanged();
    }

    function resetPosition(): void {
        pillX = -1;
        pillY = 16;
        customPosition = false;
        saveState();
        root.pillPositionChanged();
    }

    function saveState(): void {
        const data = {
            x: pillX,
            y: pillY,
            custom: customPosition
        };
        stateFile.setText(JSON.stringify(data, null, 2));
    }

    function start(): void {
        console.log("[VoiceTyping] start called!");
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        transcribedText = "";
        liveTranscript = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        state = VoiceTyping.State.Listening;
        root.started();
        startBackendRecord();
    }

    function pause(): void {
        if (!isListening)
            return;
        state = VoiceTyping.State.Paused;
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        root.paused();
        pauseBackendRecord();
    }

    function resume(): void {
        if (!isPaused)
            return;
        state = VoiceTyping.State.Listening;
        root.resumed();
        resumeBackendRecord();
    }

    function togglePause(): void {
        if (isListening)
            pause();
        else if (isPaused)
            resume();
    }

    function toggle(): void {
        if (active)
            finish();
        else
            start();
    }

    function cancel(): void {
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        liveTranscript = "";
        transcribedText = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        stopBackend(true);
        state = VoiceTyping.State.Idle;
        root.cancelled();
    }

    function finish(): void {
        if (!active)
            return;
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        liveTranscript = "";
        transcribedText = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        stopBackend(false);
        state = VoiceTyping.State.Idle;
        root.completed("");
    }

    function onTranscriptionFinished(text: string): void {
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        liveTranscript = "";
        transcribedText = text.trim();
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        state = VoiceTyping.State.Idle;
        if (transcribedText)
            root.completed(transcribedText);
    }

    function startBackendRecord(): void {
        const scriptPath = Quickshell.shellPath("scripts/voice-type.py");
        console.log("[VoiceTyping] starting backend script:", scriptPath);
        backendProc.exec(["python3", "-u", scriptPath, "start"]);
    }

    function pauseBackendRecord(): void {
        controlProc.exec(["python3", Quickshell.shellPath("scripts/voice-type.py"), "pause"]);
    }

    function resumeBackendRecord(): void {
        controlProc.exec(["python3", Quickshell.shellPath("scripts/voice-type.py"), "resume"]);
    }

    function stopBackend(cancelOnly: bool): void {
        const action = cancelOnly ? "cancel" : "finish";
        controlProc.exec(["python3", Quickshell.shellPath("scripts/voice-type.py"), action]);
    }

    NumberAnimation on wavePhase {
        running: root.isListening
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 1200
    }

    Timer {
        id: doneTimer

        interval: 1800
        onTriggered: root.cancel()
    }

    Timer {
        id: commitPreviewTimer

        interval: 1600
        onTriggered: root.showingCommitPreview = false
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/voice-pill.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && typeof data.x === "number" && typeof data.y === "number") {
                    root.pillX = data.x;
                    root.pillY = data.y;
                    root.customPosition = Boolean(data.custom);
                    root.pillPositionChanged();
                }
            } catch (e) {
                // ignore
            }
        }
    }

    Process {
        id: controlProc
    }

    Process {
        id: backendProc

        onExited: (exitCode, exitStatus) => {
            root.audioLevel = 0.0;
            root.barLevels = [0.0, 0.0, 0.0, 0.0];
            root.state = VoiceTyping.State.Idle;
        }

        stderr: SplitParser {
            onRead: data => console.log("[VoiceTyping/err]", data)
        }

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.startsWith("PARTIAL:")) {
                    root.liveTranscript = line.slice(8).trim();
                } else if (line.startsWith("COMMIT_TEXT:")) {
                    root.transcribedText = line.slice(12).trim();
                    root.lastCommittedText = root.transcribedText;
                    root.liveTranscript = "";
                    if (root.transcribedText) {
                        root.showingCommitPreview = true;
                        commitPreviewTimer.restart();
                        root.completed(root.transcribedText);
                    }
                } else if (line.startsWith("COMMIT_UNDO:")) {
                    root.transcribedText = "Undo";
                    root.lastCommittedText = "Undo";
                    root.liveTranscript = "";
                    root.showingCommitPreview = true;
                    commitPreviewTimer.restart();
                } else if (line.startsWith("TEXT:")) {
                    root.onTranscriptionFinished(line.slice(5));
                } else if (line.startsWith("LEVELS:")) {
                    const parts = line.slice(7).split(",");
                    if (parts.length === 4) {
                        const b0 = parseFloat(parts[0]) || 0.0;
                        const b1 = parseFloat(parts[1]) || 0.0;
                        const b2 = parseFloat(parts[2]) || 0.0;
                        const b3 = parseFloat(parts[3]) || 0.0;
                        root.barLevels = [b0, b1, b2, b3];
                        root.audioLevel = (b0 + b1 + b2 + b3) / 4.0;
                    }
                } else if (line.startsWith("LEVEL:")) {
                    const lvl = parseFloat(line.slice(6));
                    if (!isNaN(lvl)) {
                        root.audioLevel = lvl;
                        root.barLevels = [lvl * 0.85, lvl * 1.25, lvl * 1.10, lvl * 0.75];
                    }
                } else if (line === "AUTO_PAUSE") {
                    root.pause();
                } else if (line === "SILENCE_AUTOCOMMIT") {
                    // Handled automatically by backend commit
                }
            }
        }
    }
}
