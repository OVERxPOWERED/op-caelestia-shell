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

    // Appearance & animation settings (persisted in voice-pill.json)
    property string theme: "classic" // "classic" | "compact" | "wave"
    property string positionPreset: "top-center" // "top-center" | "bottom-center" | "top-left" | "top-right" | "bottom-left" | "bottom-right" | "custom"
    property int widgetScale: 100
    property int animationSpeed: 100
    property bool enableAnimations: true
    property bool transcriptionPreview: true
    property bool liveWaveform: true

    property real audioLevel: 0.0
    property var barLevels: [0.0, 0.0, 0.0, 0.0]
    property real wavePhase: 0.0
    property string liveTranscript: ""
    property string lastCommittedText: ""
    property string transcribedText: ""
    property string doneMessage: ""
    property bool showingCommitPreview: false
    property bool restartingBackend: false

    readonly property real scaleFactor: Math.max(0.75, Math.min(1.5, widgetScale / 100.0))
    readonly property real speedFactor: Math.max(0.5, Math.min(2.0, animationSpeed / 100.0))

    readonly property string previewTranscript: {
        if (liveTranscript && liveTranscript !== "Listening…" && liveTranscript !== "Listening...")
            return liveTranscript;
        if (showingCommitPreview && lastCommittedText)
            return lastCommittedText;
        return "";
    }

    readonly property string statusText: {
        switch (state) {
        case VoiceTyping.State.Listening:
            return Tr.tr("Listening");
        case VoiceTyping.State.Paused:
            return Tr.tr("Paused");
        case VoiceTyping.State.Transcribing:
            return Tr.tr("Transcribing");
        case VoiceTyping.State.Done:
            return doneMessage || Tr.tr("Dictation inserted");
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

    function setTheme(value: string): void {
        if (value !== "classic" && value !== "compact" && value !== "wave")
            return;
        if (theme === value)
            return;
        theme = value;
        saveState();
    }

    function setPositionPreset(preset: string): void {
        const valid = ["top-center", "bottom-center", "top-left", "top-right", "bottom-left", "bottom-right"];
        if (!valid.includes(preset))
            return;
        positionPreset = preset;
        customPosition = false;
        saveState();
        root.pillPositionChanged();
    }

    function setWidgetScale(value: int): void {
        const clamped = Math.max(75, Math.min(150, Math.round(value)));
        if (widgetScale === clamped)
            return;
        widgetScale = clamped;
        saveState();
    }

    function setAnimationSpeed(value: int): void {
        const clamped = Math.max(50, Math.min(200, Math.round(value)));
        if (animationSpeed === clamped)
            return;
        animationSpeed = clamped;
        saveState();
    }

    function setEnableAnimations(enabled: bool): void {
        if (enableAnimations === enabled)
            return;
        enableAnimations = enabled;
        saveState();
    }

    function setTranscriptionPreview(enabled: bool): void {
        if (transcriptionPreview === enabled)
            return;
        transcriptionPreview = enabled;
        saveState();
    }

    function setLiveWaveform(enabled: bool): void {
        if (liveWaveform === enabled)
            return;
        liveWaveform = enabled;
        saveState();
    }

    function savePosition(x: real, y: real): void {
        pillX = Math.round(x);
        pillY = Math.round(y);
        customPosition = true;
        positionPreset = "custom";
        saveState();
        root.pillPositionChanged();
    }

    function resetPosition(): void {
        pillX = -1;
        pillY = 16;
        customPosition = false;
        positionPreset = "top-center";
        saveState();
        root.pillPositionChanged();
    }

    function saveState(): void {
        const data = {
            x: pillX,
            y: pillY,
            custom: customPosition,
            theme: theme,
            positionPreset: positionPreset,
            widgetScale: widgetScale,
            animationSpeed: animationSpeed,
            enableAnimations: enableAnimations,
            transcriptionPreview: transcriptionPreview,
            liveWaveform: liveWaveform
        };
        stateFile.setText(JSON.stringify(data, null, 2));
    }

    function start(): void {
        console.log("[VoiceTyping] start called!");
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        doneMessage = "";
        transcribedText = "";
        liveTranscript = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        state = VoiceTyping.State.Listening;
        root.started();
        if (backendProc.running) {
            restartingBackend = true;
            stopBackend(true);
        } else {
            restartingBackend = false;
            startBackendRecord();
        }
    }

    function pause(fromBackend = false): void {
        if (!isListening)
            return;
        state = VoiceTyping.State.Paused;
        liveTranscript = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        root.paused();
        if (!fromBackend)
            pauseBackendRecord();
    }

    function resume(): void {
        if (!isPaused)
            return;
        liveTranscript = "";
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
        if (isPaused)
            resume();
        else if (active && !isDone)
            finish();
        else
            start();
    }

    function cancel(): void {
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        doneMessage = "";
        liveTranscript = "";
        transcribedText = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        stopBackend(true);
        state = VoiceTyping.State.Idle;
        root.cancelled();
    }

    function dismissDone(): void {
        doneTimer.stop();
        showingCommitPreview = false;
        doneMessage = "";
        liveTranscript = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        state = VoiceTyping.State.Idle;
    }

    function finish(): void {
        if (!active || isDone)
            return;
        doneTimer.stop();
        commitPreviewTimer.stop();
        showingCommitPreview = false;
        liveTranscript = "";
        transcribedText = "";
        lastCommittedText = "";
        audioLevel = 0.0;
        barLevels = [0.0, 0.0, 0.0, 0.0];
        doneMessage = Tr.tr("Dictation inserted");
        stopBackend(false);
        state = VoiceTyping.State.Done;
        doneTimer.restart();
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
        doneMessage = Tr.tr("Dictation inserted");
        state = VoiceTyping.State.Done;
        doneTimer.restart();
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
        running: root.isListening && root.enableAnimations
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: Math.max(450, Math.round(1200 / root.speedFactor))
    }

    Timer {
        id: doneTimer

        interval: 1100
        onTriggered: root.dismissDone()
    }

    Timer {
        id: commitPreviewTimer

        interval: 1800
        onTriggered: root.showingCommitPreview = false
    }

    FileView {
        id: stateFile

        path: `${Paths.state}/voice-pill.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data) {
                    if (typeof data.x === "number" && typeof data.y === "number") {
                        root.pillX = data.x;
                        root.pillY = data.y;
                        root.customPosition = Boolean(data.custom);
                    }
                    if (typeof data.theme === "string" && ["classic", "compact", "wave"].includes(data.theme))
                        root.theme = data.theme;
                    if (typeof data.positionPreset === "string")
                        root.positionPreset = data.positionPreset;
                    else if (root.customPosition)
                        root.positionPreset = "custom";
                    if (typeof data.widgetScale === "number")
                        root.widgetScale = Math.max(75, Math.min(150, Math.round(data.widgetScale)));
                    if (typeof data.animationSpeed === "number")
                        root.animationSpeed = Math.max(50, Math.min(200, Math.round(data.animationSpeed)));
                    if (typeof data.enableAnimations === "boolean")
                        root.enableAnimations = data.enableAnimations;
                    if (typeof data.transcriptionPreview === "boolean")
                        root.transcriptionPreview = data.transcriptionPreview;
                    if (typeof data.liveWaveform === "boolean")
                        root.liveWaveform = data.liveWaveform;
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
            if (root.restartingBackend) {
                root.restartingBackend = false;
                if (root.active && !root.isDone) {
                    root.startBackendRecord();
                    return;
                }
            }
            root.audioLevel = 0.0;
            root.barLevels = [0.0, 0.0, 0.0, 0.0];
            if (root.state !== VoiceTyping.State.Done)
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
                    root.pause(true);
                } else if (line === "SILENCE_AUTOCOMMIT") {
                    // Handled automatically by backend commit
                }
            }
        }
    }
}
