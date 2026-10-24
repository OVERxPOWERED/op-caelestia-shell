pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n

Singleton {
    id: root

    enum Mode {
        Focus = 0,
        ShortBreak = 1,
        LongBreak = 2
    }

    property int mode: Pomodoro.Mode.Focus
    property bool running: false
    property int cycleCount: 0 // Completed focus sessions in the current round (0 to sessionsBeforeLongBreak - 1)

    // Durations configured via shell.json dashboard.pomodoro (with defaults: 25 / 5 / 15 mins)
    readonly property int focusMinutes: GlobalConfig.dashboard?.pomodoro?.focusDuration ?? 25
    readonly property int shortBreakMinutes: GlobalConfig.dashboard?.pomodoro?.shortBreakDuration ?? 5
    readonly property int longBreakMinutes: GlobalConfig.dashboard?.pomodoro?.longBreakDuration ?? 15
    readonly property int sessionsBeforeLongBreak: GlobalConfig.dashboard?.pomodoro?.sessionsBeforeLongBreak ?? 4

    readonly property int focusDurationSeconds: focusMinutes * 60
    readonly property int shortBreakDurationSeconds: shortBreakMinutes * 60
    readonly property int longBreakDurationSeconds: longBreakMinutes * 60

    readonly property int currentDurationSeconds: {
        switch (mode) {
        case Pomodoro.Mode.ShortBreak:
            return shortBreakDurationSeconds;
        case Pomodoro.Mode.LongBreak:
            return longBreakDurationSeconds;
        default:
            return focusDurationSeconds;
        }
    }

    property int timeRemaining: currentDurationSeconds
    property int totalTime: currentDurationSeconds

    readonly property real progress: totalTime > 0 ? Math.max(0, Math.min(1, 1.0 - (timeRemaining / totalTime))) : 0.0

    readonly property string minutesStr: {
        const m = Math.floor(timeRemaining / 60);
        return m < 10 ? "0" + m : m.toString();
    }

    readonly property string secondsStr: {
        const s = timeRemaining % 60;
        return s < 10 ? "0" + s : s.toString();
    }

    readonly property string formattedTime: `${minutesStr}:${secondsStr}`

    readonly property string modeName: {
        switch (mode) {
        case Pomodoro.Mode.ShortBreak:
            return qsTr("Short Break");
        case Pomodoro.Mode.LongBreak:
            return qsTr("Long Break");
        default:
            return qsTr("Focus");
        }
    }

    readonly property string shortModeName: {
        switch (mode) {
        case Pomodoro.Mode.ShortBreak:
            return qsTr("Break");
        case Pomodoro.Mode.LongBreak:
            return qsTr("Long");
        default:
            return qsTr("Focus");
        }
    }

    readonly property string modeIcon: {
        switch (mode) {
        case Pomodoro.Mode.ShortBreak:
            return "coffee";
        case Pomodoro.Mode.LongBreak:
            return "self_improvement";
        default:
            return "timer";
        }
    }

    // Target end timestamp (ms) to ensure zero drift across frames and sleep
    property double targetEndTime: 0

    function start(): void {
        if (timeRemaining <= 0)
            resetCurrent();
        targetEndTime = Date.now() + timeRemaining * 1000;
        running = true;
    }

    function pause(): void {
        if (!running)
            return;
        timeRemaining = Math.max(0, Math.round((targetEndTime - Date.now()) / 1000));
        running = false;
    }

    function toggle(): void {
        running ? pause() : start();
    }

    function reset(): void {
        running = false;
        resetCurrent();
    }

    function resetCurrent(): void {
        timeRemaining = currentDurationSeconds;
        totalTime = currentDurationSeconds;
    }

    function skip(): void {
        running = false;
        advanceSession();
    }

    function setMode(newMode: int): void {
        if (mode === newMode)
            return;
        running = false;
        mode = newMode;
        resetCurrent();
    }

    function advanceSession(): void {
        if (mode === Pomodoro.Mode.Focus) {
            const nextCycle = cycleCount + 1;
            if (nextCycle >= sessionsBeforeLongBreak) {
                cycleCount = 0;
                mode = Pomodoro.Mode.LongBreak;
                Toaster.toast(Tr.tr("Pomodoro Focus Complete"), Tr.tr("Great job! Time for a long break."), "timer", Toast.Success);
            } else {
                cycleCount = nextCycle;
                mode = Pomodoro.Mode.ShortBreak;
                Toaster.toast(Tr.tr("Pomodoro Focus Complete"), Tr.tr("Time for a short break."), "timer", Toast.Success);
            }
        } else {
            mode = Pomodoro.Mode.Focus;
            Toaster.toast(Tr.tr("Break Finished"), Tr.tr("Ready to start another focus session?"), "alarm", Toast.Info);
        }
        resetCurrent();
    }

    Timer {
        id: ticker

        interval: 250
        repeat: true
        running: root.running

        onTriggered: {
            const remaining = Math.max(0, Math.round((root.targetEndTime - Date.now()) / 1000));
            root.timeRemaining = remaining;
            if (remaining <= 0) {
                root.running = false;
                root.advanceSession();
            }
        }
    }

    onFocusMinutesChanged: {
        if (!running && mode === Pomodoro.Mode.Focus)
            resetCurrent();
    }
    onShortBreakMinutesChanged: {
        if (!running && mode === Pomodoro.Mode.ShortBreak)
            resetCurrent();
    }
    onLongBreakMinutesChanged: {
        if (!running && mode === Pomodoro.Mode.LongBreak)
            resetCurrent();
    }
}
