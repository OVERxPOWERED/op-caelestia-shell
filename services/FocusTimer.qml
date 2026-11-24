pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    function clamp(val: real, minVal: real, maxVal: real): real {
        return Math.max(minVal, Math.min(maxVal, val));
    }

    // config-backed, clamped, read-only
    readonly property int focusMins: clamp(GlobalConfig.focus.focusMins, 5, 180)
    readonly property int shortBreakMins: clamp(GlobalConfig.focus.shortBreakMins, 1, 60)
    readonly property int longBreakMins: clamp(GlobalConfig.focus.longBreakMins, 5, 180)
    readonly property int cyclesBeforeLongBreak: clamp(GlobalConfig.focus.cyclesBeforeLongBreak, 2, 8)

    property string mode: "timer"          // "timer" | "stopwatch"
    property string phase: "focus"         // "focus" | "shortBreak" | "longBreak"
    property string subject: ""            // "" = untagged
    property int remaining: 0              // countdown seconds
    property int elapsed: 0                // stopwatch seconds
    property int phaseTotal: 0             // countdown length incl. +5m extensions
    property int phaseTickSecs: 0          // seconds actually ticked in this phase
    property int cycleCount: 0             // credited focus sessions since last Big Break
    property bool running: false
    property bool sessionActive: false
    property bool dndEngaged: false
    property int distractionSecs: 0
    property bool subjectModified: false
    property bool sessionLoaded: false

    readonly property bool isStopwatch: mode === "stopwatch" && phase === "focus"
    readonly property int baseSecs: (phase === "shortBreak" ? shortBreakMins : phase === "longBreak" ? longBreakMins : focusMins) * 60
    readonly property int durationSecs: baseSecs
    readonly property bool active: sessionActive
    readonly property int completedSessions: FocusLedger.todaySessions
    readonly property int totalFocusedSecsToday: FocusLedger.todaySecs
    readonly property bool canSwitchMode: !running && phaseTickSecs === 0

    readonly property real progress: {
        if (isStopwatch) {
            let fSecs = focusMins * 60;
            return fSecs > 0 ? (elapsed % fSecs) / fSecs : 0;
        }
        return phaseTotal > 0 ? clamp(1.0 - (remaining / phaseTotal), 0.0, 1.0) : 0;
    }

    readonly property string display: {
        let v = isStopwatch ? elapsed : Math.max(0, remaining);
        let h = Math.floor(v / 3600);
        let m = Math.floor((v % 3600) / 60);
        let s = v % 60;
        let mm = m.toString().padStart(2, "0");
        let ss = s.toString().padStart(2, "0");
        if (h > 0) {
            return `${h}:${mm}:${ss}`;
        }
        return `${mm}:${ss}`;
    }

    readonly property string phaseLabel: {
        let fresh = phaseTickSecs === 0 && !running;
        if (phase === "focus") {
            if (mode === "stopwatch") {
                if (running) return Tr.tr("Flowing");
                return fresh ? Tr.tr("Ready to flow") : Tr.tr("Flow paused");
            } else {
                if (running) return Tr.tr("Focusing");
                return fresh ? Tr.tr("Ready to focus") : Tr.tr("Focus paused");
            }
        } else if (phase === "shortBreak") {
            if (running) return Tr.tr("Short break");
            return fresh ? Tr.tr("Break ready") : Tr.tr("Break paused");
        } else if (phase === "longBreak") {
            if (running) return Tr.tr("Big break");
            return fresh ? Tr.tr("Big break ready") : Tr.tr("Break paused");
        }
        return "";
    }

    readonly property string phaseIcon: phase === "focus" ? "timer" : "coffee"

    signal phaseEvent()

    readonly property FileView sessionFile: FileView {
        path: `${Paths.state}/focus_session.json`
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: {
            root.restoreSnapshot(text());
            root.sessionLoaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.sessionLoaded = true;
        }
    }

    function enterPhase(newPhase: string, autoRun: bool): void {
        phase = newPhase;
        phaseTickSecs = 0;
        elapsed = 0;
        distractionSecs = 0;
        phaseTotal = baseSecs;
        remaining = baseSecs;
        running = autoRun;
        if (autoRun)
            sessionActive = true;
        syncDnd();
        phaseEvent();
        FocusLedger.flush();
        saveSnapshot();
    }

    function creditFocus(): bool {
        let credited = phaseTickSecs >= (0.5 * focusMins * 60);
        if (credited) {
            cycleCount++;
            FocusLedger.addSession();
        }
        return credited;
    }

    function nextBreak(): string {
        return cycleCount >= cyclesBeforeLongBreak ? "longBreak" : "shortBreak";
    }

    function completePhase(): void {
        if (phase === "focus") {
            creditFocus();
            Audio.playFocusEnd();
            Toaster.toast(Tr.tr("Study session complete"), Tr.tr("Time for a break."), "task_alt", Toast.Info);
            enterPhase(nextBreak(), GlobalConfig.focus.autoPlay);
        } else {
            if (phase === "longBreak")
                cycleCount = 0;
            Audio.playBreakEnd();
            Toaster.toast(Tr.tr("Break finished"), Tr.tr("Ready for your next focus session."), "timer", Toast.Info);
            enterPhase("focus", GlobalConfig.focus.autoPlay);
        }
    }

    function skipPhase(): void {
        if (!sessionActive)
            return;
        if (phase === "focus") {
            creditFocus();
            enterPhase(nextBreak(), true);
        } else {
            if (phase === "longBreak")
                cycleCount = 0;
            enterPhase("focus", true);
        }
    }

    function toggle(): void {
        if (!running && !isStopwatch && remaining <= 0)
            remaining = phaseTotal;
        running = !running;
        if (running)
            sessionActive = true;
        else
            FocusLedger.flush();
        syncDnd();
        phaseEvent();
        saveSnapshot();
    }

    function reset(): void {
        running = false;
        sessionActive = false;
        phase = "focus";
        cycleCount = 0;
        phaseTickSecs = 0;
        elapsed = 0;
        distractionSecs = 0;
        let fSecs = focusMins * 60;
        phaseTotal = fSecs;
        remaining = fSecs;
        syncDnd();
        FocusLedger.flush();
        saveSnapshot();
    }

    function setPhase(p: string): void {
        if (phase === "longBreak" && p === "focus")
            cycleCount = 0;
        enterPhase(p, false);
    }

    function setMode(m: string): void {
        if (!canSwitchMode)
            return;
        if (m !== "timer" && m !== "stopwatch")
            return;
        if (m === mode && !(m === "stopwatch" && phase !== "focus"))
            return;
        if (m === "stopwatch")
            phase = "focus";
        mode = m;
        syncIdle();
        saveSnapshot();
    }

    function setSubject(name: string): void {
        subjectModified = true;
        subject = (subject === name) ? "" : name;
        FocusLedger.setLastSubject(subject);
        saveSnapshot();
    }

    function cycleSubject(): void {
        const list = Array.from(GlobalConfig.focus.subjects || []);
        if (list.length === 0)
            return;
        list.push("");
        const idx = list.indexOf(subject);
        subjectModified = true;
        subject = list[(idx + 1) % list.length];
        FocusLedger.setLastSubject(subject);
        saveSnapshot();
    }

    function applyPreset(fMins: int, sMins: int): void {
        const f = clamp(fMins, 5, 180);
        const s = clamp(sMins, 1, 60);
        GlobalConfig.focus.focusMins = f;
        GlobalConfig.focus.shortBreakMins = s;
        mode = "timer";
        running = false;
        sessionActive = false;
        phase = "focus";
        cycleCount = 0;
        phaseTickSecs = 0;
        elapsed = 0;
        distractionSecs = 0;
        phaseTotal = f * 60;
        remaining = f * 60;
        syncDnd();
        FocusLedger.flush();
        saveSnapshot();
    }

    function extend(): void {
        if (!sessionActive || isStopwatch)
            return;
        remaining += 300;
        phaseTotal += 300;
        saveSnapshot();
    }

    function reduce(): void {
        if (!sessionActive || isStopwatch)
            return;
        const next = Math.max(60, remaining - 300);
        const delta = Math.max(0, remaining - next);
        remaining = next;
        phaseTotal = Math.max(remaining, phaseTotal - delta);
        saveSnapshot();
    }

    function recordDistractionSecond(appClass: string): void {
        if (running && phase === "focus")
            distractionSecs++;
    }

    function adjust(mins: int): void {
        if (running)
            return;
        if (phase === "shortBreak") {
            GlobalConfig.focus.shortBreakMins = clamp(shortBreakMins + mins, 1, 60);
        } else if (phase === "longBreak") {
            GlobalConfig.focus.longBreakMins = clamp(longBreakMins + mins, 5, 180);
        } else {
            GlobalConfig.focus.focusMins = clamp(focusMins + mins, 5, 180);
        }
        syncIdle();
    }

    function syncIdle(): void {
        if (!running && phaseTickSecs === 0) {
            phaseTotal = baseSecs;
            remaining = baseSecs;
        }
    }

    onFocusMinsChanged: syncIdle()
    onShortBreakMinsChanged: syncIdle()
    onLongBreakMinsChanged: syncIdle()

    function syncDnd(): void {
        if (!GlobalConfig.focus.autoDnd || !sessionActive) {
            releaseDnd();
            return;
        }
        if (running && phase === "focus") {
            Notifs.dnd = true;
            dndEngaged = true;
        } else if (dndEngaged) {
            Notifs.dnd = false;
            dndEngaged = false;
        }
    }

    function releaseDnd(): void {
        if (dndEngaged) {
            Notifs.dnd = false;
            dndEngaged = false;
        }
    }

    onRunningChanged: syncDnd()
    onPhaseChanged: syncDnd()
    onSessionActiveChanged: syncDnd()

    function saveSnapshot(): void {
        if (!sessionLoaded)
            return;
        let snap = {
            version: 1,
            sessionActive: root.sessionActive,
            running: root.running,
            mode: root.mode,
            phase: root.phase,
            remaining: root.remaining,
            elapsed: root.elapsed,
            distractionSecs: root.distractionSecs,
            phaseTotal: root.phaseTotal,
            phaseTickSecs: root.phaseTickSecs,
            cycleCount: root.cycleCount,
            subject: root.subject,
            dndEngaged: root.dndEngaged,
            savedAt: Date.now()
        };
        sessionFile.setText(JSON.stringify(snap, null, 2));
    }

    function restoreSnapshot(rawText: string): void {
        try {
            if (!rawText || rawText.trim() === "")
                return;
            let snap = JSON.parse(rawText);
            if (typeof snap !== "object" || snap === null)
                return;
            if (snap.version !== 1)
                return;

            const validSubjects = Array.from(GlobalConfig.focus.subjects || []);
            const snapSubj = (typeof snap.subject === "string" && (snap.subject === "" || validSubjects.indexOf(snap.subject) !== -1))
                ? snap.subject
                : "";
            if (typeof snap.subject === "string" && snap.subject !== "" && snapSubj === "")
                FocusLedger.setLastSubject("");

            const savedAt = (typeof snap.savedAt === "number" && isFinite(snap.savedAt)) ? snap.savedAt : 0;
            const todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
            const savedDateStr = savedAt > 0 ? Qt.formatDate(new Date(savedAt), "yyyy-MM-dd") : "";
            const ageMs = savedAt > 0 ? (Date.now() - savedAt) : Infinity;

            // Discard stale snapshots or snapshots from a prior local date
            if (savedAt <= 0 || savedDateStr !== todayStr || ageMs < -60000 || ageMs > 12 * 3600 * 1000) {
                if (snap.dndEngaged)
                    Notifs.dnd = false;
                if (!subjectModified)
                    subject = snapSubj;
                return;
            }

            if (!subjectModified)
                subject = snapSubj;
            if (!snap.sessionActive)
                return;
            if (["focus", "shortBreak", "longBreak"].indexOf(snap.phase) === -1)
                return;
            if (["timer", "stopwatch"].indexOf(snap.mode) === -1)
                return;
            if (typeof snap.remaining !== "number" || !isFinite(snap.remaining) || snap.remaining < 0 || snap.remaining > 36000)
                return;

            const safeInt = v => (typeof v === "number" && isFinite(v)) ? Math.max(0, Math.round(v)) : 0;
            const staleRun = ageMs > 120000;

            mode = snap.mode;
            phase = snap.phase;
            remaining = safeInt(snap.remaining);
            elapsed = safeInt(snap.elapsed);
            distractionSecs = safeInt(snap.distractionSecs);
            phaseTotal = (typeof snap.phaseTotal === "number" && isFinite(snap.phaseTotal) && snap.phaseTotal > 0)
                ? Math.max(remaining, Math.round(snap.phaseTotal))
                : baseSecs;
            phaseTickSecs = safeInt(snap.phaseTickSecs);
            cycleCount = safeInt(snap.cycleCount);
            sessionActive = true;
            dndEngaged = staleRun ? false : !!snap.dndEngaged;
            running = staleRun ? false : !!snap.running;

            if (snap.dndEngaged && !(running && phase === "focus")) {
                Notifs.dnd = false;
                dndEngaged = false;
            } else {
                syncDnd();
            }

            Toaster.toast(
                Tr.tr("Focus session restored"),
                staleRun ? Tr.tr("Restored previous focus session (paused).") : Tr.tr("Resumed previous focus state."),
                "history",
                Toast.Info
            );
        } catch (e) {}
    }

    Connections {
        target: GlobalConfig.focus

        function onAutoDndChanged(): void {
            root.syncDnd();
        }

        function onSubjectsChanged(): void {
            const list = Array.from(GlobalConfig.focus.subjects || []);
            if (root.subject !== "" && list.indexOf(root.subject) === -1) {
                root.subject = "";
                FocusLedger.setLastSubject("");
                root.saveSnapshot();
            } else if (FocusLedger.lastSubject !== "" && list.indexOf(FocusLedger.lastSubject) === -1) {
                FocusLedger.setLastSubject("");
            }
        }
    }

    Connections {
        target: FocusLedger

        function onReadyChanged(): void {
            if (FocusLedger.ready && !root.sessionActive && !root.subjectModified && root.subject === "" && FocusLedger.lastSubject !== "") {
                const list = Array.from(GlobalConfig.focus.subjects || []);
                if (list.indexOf(FocusLedger.lastSubject) !== -1)
                    root.subject = FocusLedger.lastSubject;
                else
                    FocusLedger.setLastSubject("");
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (FocusLedger.pauseOnSleep && !ScreenTime.screenAwake) {
                root.running = false;
                FocusLedger.flush();
                root.saveSnapshot();
                Toaster.toast(Tr.tr("Focus paused"), Tr.tr("Timer paused while screen was asleep."), "bedtime", Toast.Info);
                return;
            }
            if (root.isStopwatch)
                root.elapsed++;
            else
                root.remaining--;
            root.phaseTickSecs++;
            if (root.phase === "focus")
                FocusLedger.addFocusSecs(root.subject, 1);
            if (!root.isStopwatch && root.remaining <= 0)
                root.completePhase();
        }
    }

    Timer {
        id: persistTimer
        interval: 5000
        repeat: true
        running: root.running
        onTriggered: {
            root.saveSnapshot();
            FocusLedger.flush();
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Paths.state]);
        phaseTotal = baseSecs;
        remaining = baseSecs;
    }

    Component.onDestruction: {
        saveSnapshot();
        FocusLedger.flush();
    }

    IpcHandler {
        target: "pomodoro"

        function toggle(): void {
            root.toggle();
        }
        function reset(): void {
            root.reset();
        }
        function skip(): void {
            root.skipPhase();
        }
        function extend(): void {
            root.extend();
        }
        function reduce(): void {
            root.reduce();
        }
        function setMode(m: string): void {
            root.setMode(m);
        }
        function setSubject(s: string): void {
            root.setSubject(s);
        }
        function cycleSubject(): void {
            root.cycleSubject();
        }
        function status(): string {
            return JSON.stringify({
                phase: root.phase,
                mode: root.mode,
                running: root.running,
                remaining: root.remaining,
                elapsed: root.elapsed,
                display: root.display,
                subject: root.subject,
                cycleCount: root.cycleCount,
                completedSessions: root.completedSessions,
                distractionSecs: root.distractionSecs,
                studiedTodaySecs: FocusLedger.todaySecs
            });
        }
    }
}
