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

    property bool ready: false
    property bool corrupt: false
    property int revision: 0
    property int summaryRevision: 0
    property string todayKey: Qt.formatDate(new Date(), "yyyy-MM-dd")

    property var days: ({})
    property var pendingSecs: ({})
    property int pendingSessions: 0
    property bool pauseOnSleep: false
    property string lastSubject: ""
    property var countdowns: []
    property bool dirty: false
    property bool backedUp: false

    function defaultCountdowns(): var {
        return [];
    }

    function parseLocalDate(dateStr: string): var {
        if (!dateStr || typeof dateStr !== "string") return null;
        const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateStr.trim());
        if (!m) return null;
        const y = parseInt(m[1], 10);
        const mo = parseInt(m[2], 10) - 1;
        const d = parseInt(m[3], 10);
        const dt = new Date(y, mo, d, 12, 0, 0, 0);
        if (dt.getFullYear() !== y || dt.getMonth() !== mo || dt.getDate() !== d)
            return null;
        return dt;
    }

    function daysUntil(dateStr: string): int {
        void todayKey;
        const target = parseLocalDate(dateStr);
        if (!target) return 0;
        const now = new Date();
        now.setHours(12, 0, 0, 0);
        return Math.round((target.getTime() - now.getTime()) / 86400000);
    }

    function formatDateShort(dateStr: string): string {
        const dt = parseLocalDate(dateStr);
        return dt ? Qt.formatDate(dt, "MMM d, yyyy") : (dateStr || "");
    }

    readonly property int todaySecs: {
        revision;
        return (days[todayKey] && days[todayKey].focusSecs) ? days[todayKey].focusSecs : 0;
    }

    readonly property int todaySessions: {
        revision;
        return (days[todayKey] && days[todayKey].sessions) ? days[todayKey].sessions : 0;
    }

    readonly property bool todayRest: {
        revision;
        return (days[todayKey] && days[todayKey].restDay) ? true : false;
    }

    readonly property int weekSecs: {
        revision;
        let total = 0;
        let keys = weekKeys();
        for (let i = 0; i < keys.length; i++) {
            let d = days[keys[i]];
            if (d && d.focusSecs) total += d.focusSecs;
        }
        return total;
    }

    readonly property int weekSessions: {
        revision;
        let total = 0;
        let keys = weekKeys();
        for (let i = 0; i < keys.length; i++) {
            let d = days[keys[i]];
            if (d && d.sessions) total += d.sessions;
        }
        return total;
    }

    readonly property int weekDailyAvgSecs: {
        revision;
        let keys = weekKeys();
        let activeDays = 0;
        let total = 0;
        for (let i = 0; i < keys.length; i++) {
            let d = days[keys[i]];
            let s = (d && d.focusSecs) ? d.focusSecs : 0;
            if (s > 0) {
                activeDays++;
                total += s;
            }
        }
        return activeDays > 0 ? Math.round(total / activeDays) : 0;
    }

    property var weekNames: []

    readonly property int streak: {
        summaryRevision;
        void todayKey;
        if (!ready) return 0;
        let thr = (GlobalConfig.focus.streakThresholdMins || 30) * 60;
        let s = 0;
        let now = new Date();
        let todayStr = Qt.formatDate(now, "yyyy-MM-dd");

        function qualifies(k) {
            let d = days[k];
            return d && (d.focusSecs || 0) >= thr;
        }

        if (qualifies(todayStr)) {
            s++;
        }

        let cur = new Date(now);
        cur.setDate(cur.getDate() - 1);
        let count = 0;
        while (count < 800) {
            let k = Qt.formatDate(cur, "yyyy-MM-dd");
            if (qualifies(k)) {
                s++;
            } else if (days[k] && days[k].restDay) {
                // rest day: skipped, neither counts nor breaks
            } else {
                break;
            }
            cur.setDate(cur.getDate() - 1);
            count++;
        }
        return s;
    }

    readonly property int totalFocusSecs: {
        revision;
        let total = 0;
        for (const k in days) {
            if (days.hasOwnProperty(k) && days[k] && days[k].focusSecs)
                total += Math.round(days[k].focusSecs);
        }
        return total;
    }

    readonly property int totalSessions: {
        revision;
        let total = 0;
        for (const k in days) {
            if (days.hasOwnProperty(k) && days[k] && days[k].sessions)
                total += Math.round(days[k].sessions);
        }
        return total;
    }

    readonly property int activeDaysCount: {
        summaryRevision;
        let cnt = 0;
        for (const k in days) {
            if (days.hasOwnProperty(k) && days[k] && (days[k].focusSecs || 0) > 0)
                cnt++;
        }
        return cnt;
    }

    readonly property int bestStreak: {
        summaryRevision;
        void todayKey;
        if (!ready) return 0;
        const keys = Object.keys(days).filter(k => /^\d{4}-\d{2}-\d{2}$/.test(k)).sort();
        if (keys.length === 0) return 0;
        const thr = (GlobalConfig.focus.streakThresholdMins || 30) * 60;
        const firstDt = parseLocalDate(keys[0]);
        if (!firstDt) return streak;
        const todayDt = new Date();
        todayDt.setHours(12, 0, 0, 0);
        const todayStr = Qt.formatDate(todayDt, "yyyy-MM-dd");

        let best = 0;
        let cur = 0;
        let iter = new Date(firstDt);
        let guard = 0;
        while (iter.getTime() <= todayDt.getTime() && guard < 3650) {
            const k = Qt.formatDate(iter, "yyyy-MM-dd");
            const d = days[k];
            if (d && (d.focusSecs || 0) >= thr) {
                cur++;
                if (cur > best) best = cur;
            } else if (d && d.restDay) {
                // rest day: neither increments nor breaks streak
            } else if (k !== todayStr) {
                cur = 0;
            }
            iter.setDate(iter.getDate() + 1);
            guard++;
        }
        return Math.max(best, streak);
    }

    readonly property FileView backupFile: FileView {
        path: `${Paths.state}/focus_ledger.json.bak`
        printErrors: false
    }

    readonly property FileView ledgerFile: FileView {
        path: `${Paths.state}/focus_ledger.json`
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: root.loadData(text())
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.days = {};
                root.pauseOnSleep = false;
                root.lastSubject = "";
                root.countdowns = root.defaultCountdowns();
                root.ready = true;
                root.mergePending();
                root.refreshWeekNames();
                root.revision++;
                root.summaryRevision++;
            } else {
                root.ready = false;
            }
        }
    }

    function checkTodayKey(): void {
        let k = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (k !== todayKey) {
            todayKey = k;
            refreshWeekNames();
            revision++;
            summaryRevision++;
        }
    }

    function addFocusSecs(subject: string, secs: int): void {
        checkTodayKey();
        let sKey = subject || "__none__";
        if (!ready) {
            pendingSecs[sKey] = (pendingSecs[sKey] || 0) + secs;
            return;
        }

        if (!days[todayKey]) {
            days[todayKey] = {
                focusSecs: 0,
                sessions: 0,
                restDay: false,
                subjects: {}
            };
        }
        if (!days[todayKey].subjects) {
            days[todayKey].subjects = {};
        }

        const prevTotal = days[todayKey].focusSecs || 0;
        const nextTotal = prevTotal + secs;
        const thr = (GlobalConfig.focus.streakThresholdMins || 30) * 60;
        const crossedMinute = Math.floor(prevTotal / 60) !== Math.floor(nextTotal / 60);
        const crossedFirst = prevTotal === 0 && nextTotal > 0;
        const crossedThreshold = prevTotal < thr && nextTotal >= thr;

        days[todayKey].focusSecs = nextTotal;
        days[todayKey].subjects[sKey] = (days[todayKey].subjects[sKey] || 0) + secs;
        dirty = true;
        revision++;
        if (crossedMinute || crossedFirst || crossedThreshold)
            summaryRevision++;
    }

    function addSession(): void {
        checkTodayKey();
        if (!ready) {
            pendingSessions++;
            return;
        }

        if (!days[todayKey]) {
            days[todayKey] = {
                focusSecs: 0,
                sessions: 0,
                restDay: false,
                subjects: {}
            };
        }
        days[todayKey].sessions = (days[todayKey].sessions || 0) + 1;
        dirty = true;
        revision++;
        summaryRevision++;
        saveDebounce.restart();
    }

    function setPauseOnSleep(on: bool): void {
        if (!ready || corrupt) return;
        const next = !!on;
        if (pauseOnSleep === next) return;
        pauseOnSleep = next;
        dirty = true;
        revision++;
        saveDebounce.restart();
    }

    function setLastSubject(subj: string): void {
        if (!ready || corrupt) return;
        const next = typeof subj === "string" ? subj : "";
        if (lastSubject === next) return;
        lastSubject = next;
        dirty = true;
        saveDebounce.restart();
    }

    function addCountdown(title: string, dateStr: string): bool {
        if (!ready || corrupt) return false;
        const cleanTitle = (title || "").trim();
        const cleanDate = (dateStr || "").trim();
        if (cleanTitle === "" || !parseLocalDate(cleanDate)) return false;
        const arr = Array.isArray(countdowns) ? countdowns.slice() : [];
        arr.push({
            id: "cd-" + Date.now() + "-" + Math.floor(Math.random() * 1000),
            title: cleanTitle,
            date: cleanDate
        });
        countdowns = arr;
        dirty = true;
        revision++;
        summaryRevision++;
        saveDebounce.restart();
        return true;
    }

    function removeCountdown(id: string): void {
        if (!ready || corrupt || !id) return;
        const arr = Array.isArray(countdowns) ? countdowns.filter(c => c && c.id !== id) : [];
        countdowns = arr;
        dirty = true;
        revision++;
        summaryRevision++;
        saveDebounce.restart();
    }

    function updateCountdown(id: string, title: string, dateStr: string): bool {
        if (!ready || corrupt || !id) return false;
        const cleanTitle = (title || "").trim();
        const cleanDate = (dateStr || "").trim();
        if (cleanTitle === "" || !parseLocalDate(cleanDate)) return false;
        const arr = Array.isArray(countdowns) ? countdowns.slice() : [];
        let changed = false;
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] && arr[i].id === id) {
                arr[i] = { id: id, title: cleanTitle, date: cleanDate };
                changed = true;
                break;
            }
        }
        if (!changed) return false;
        countdowns = arr;
        dirty = true;
        revision++;
        summaryRevision++;
        saveDebounce.restart();
        return true;
    }

    function reassignSubjectForScope(scopeOffset: int, fromSubj: string, toSubj: string): void {
        if (!ready || corrupt || !fromSubj || !toSubj || fromSubj === toSubj) return;
        let keys = [];
        if (scopeOffset >= 8 || scopeOffset < 0) {
            keys = Object.keys(days);
        } else if (scopeOffset === 0) {
            keys = weekKeys();
        } else {
            const d = new Date();
            d.setHours(12, 0, 0, 0);
            d.setDate(d.getDate() - (scopeOffset - 1));
            keys = [Qt.formatDate(d, "yyyy-MM-dd")];
        }
        let changed = false;
        for (let i = 0; i < keys.length; i++) {
            const dayObj = days[keys[i]];
            if (dayObj && dayObj.subjects && dayObj.subjects[fromSubj] > 0) {
                const secs = Math.round(dayObj.subjects[fromSubj]);
                dayObj.subjects[toSubj] = Math.round(dayObj.subjects[toSubj] || 0) + secs;
                delete dayObj.subjects[fromSubj];
                changed = true;
            }
        }
        if (changed) {
            dirty = true;
            refreshWeekNames();
            revision++;
            summaryRevision++;
            saveDebounce.restart();
        }
    }

    function setRestDay(key: string, on: bool): void {
        if (!ready || corrupt) return;
        if (!days[key]) {
            days[key] = {
                focusSecs: 0,
                sessions: 0,
                restDay: false,
                subjects: {}
            };
        }
        days[key].restDay = !!on;
        dirty = true;
        revision++;
        summaryRevision++;
        saveDebounce.restart();
    }

    function weekKeys(): var {
        void todayKey;
        let now = new Date();
        let keys = [];
        let offset = (now.getDay() + 6) % 7; // Monday = 0, Sunday = 6
        let monday = new Date(now);
        monday.setDate(now.getDate() - offset);

        for (let i = 0; i < 7; i++) {
            let cur = new Date(monday);
            cur.setDate(monday.getDate() + i);
            keys.push(Qt.formatDate(cur, "yyyy-MM-dd"));
        }
        return keys;
    }

    function weekSecsFor(name: string): int {
        revision;
        let sKey = name || "__none__";
        let total = 0;
        let keys = weekKeys();
        for (let i = 0; i < keys.length; i++) {
            let d = days[keys[i]];
            if (d && d.subjects && d.subjects[sKey]) {
                total += d.subjects[sKey];
            }
        }
        return total;
    }

    function refreshWeekNames(): void {
        let keys = weekKeys();
        let map = {};
        for (let i = 0; i < keys.length; i++) {
            let d = days[keys[i]];
            if (d && d.subjects) {
                for (let k in d.subjects) {
                    if (d.subjects.hasOwnProperty(k)) {
                        let s = Math.round(d.subjects[k] || 0);
                        if (s > 0) {
                            map[k] = (map[k] || 0) + s;
                        }
                    }
                }
            }
        }
        let list = Object.keys(map).filter(k => map[k] > 0).sort((a, b) => (map[b] || 0) - (map[a] || 0));
        if (JSON.stringify(list) !== JSON.stringify(weekNames)) {
            weekNames = list;
        }
    }

    // scopeOffset: 0 = This Week (Mon..Sun), 1 = Today, 2 = Yesterday, ..., 7 = 6 days ago, 8 (or <0) = All Time
    function scopeTotalSecs(scopeOffset: int): int {
        revision;
        void todayKey;
        if (scopeOffset >= 8 || scopeOffset < 0) {
            return totalFocusSecs;
        }
        if (scopeOffset === 0) {
            return weekSecs;
        }
        const d = new Date();
        d.setHours(12, 0, 0, 0);
        d.setDate(d.getDate() - (scopeOffset - 1));
        const key = Qt.formatDate(d, "yyyy-MM-dd");
        return (days[key] && days[key].focusSecs) ? Math.round(days[key].focusSecs) : 0;
    }

    function subjectBreakdownForScope(scopeOffset: int, topN: int): var {
        summaryRevision;
        void todayKey;
        const limit = (typeof topN === "number" && topN > 0) ? topN : 5;
        const map = {};
        if (scopeOffset >= 8 || scopeOffset < 0) {
            for (const key in days) {
                if (!days.hasOwnProperty(key)) continue;
                const dayObj = days[key];
                if (dayObj && dayObj.subjects) {
                    for (const subj in dayObj.subjects) {
                        if (dayObj.subjects.hasOwnProperty(subj)) {
                            const s = Math.round(dayObj.subjects[subj] || 0);
                            if (s > 0) map[subj] = (map[subj] || 0) + s;
                        }
                    }
                }
            }
        } else if (scopeOffset === 0) {
            const keys = weekKeys();
            for (let i = 0; i < keys.length; i++) {
                const dayObj = days[keys[i]];
                if (dayObj && dayObj.subjects) {
                    for (const subj in dayObj.subjects) {
                        if (dayObj.subjects.hasOwnProperty(subj)) {
                            const s = Math.round(dayObj.subjects[subj] || 0);
                            if (s > 0) map[subj] = (map[subj] || 0) + s;
                        }
                    }
                }
            }
        } else {
            const d = new Date();
            d.setHours(12, 0, 0, 0);
            d.setDate(d.getDate() - (scopeOffset - 1));
            const key = Qt.formatDate(d, "yyyy-MM-dd");
            const dayObj = days[key];
            if (dayObj && dayObj.subjects) {
                for (const subj in dayObj.subjects) {
                    if (dayObj.subjects.hasOwnProperty(subj)) {
                        const s = Math.round(dayObj.subjects[subj] || 0);
                        if (s > 0) map[subj] = (map[subj] || 0) + s;
                    }
                }
            }
        }

        const list = [];
        for (const subj in map) {
            if (map.hasOwnProperty(subj) && map[subj] >= 1) {
                list.push({
                    subject: subj,
                    seconds: map[subj]
                });
            }
        }
        list.sort((a, b) => b.seconds - a.seconds);
        return list.slice(0, limit);
    }

    function heatmapWeeks(numWeeks: int): var {
        summaryRevision;
        void todayKey;
        const count = (typeof numWeeks === "number" && numWeeks > 0) ? Math.round(numWeeks) : 16;
        const now = new Date();
        now.setHours(12, 0, 0, 0);
        const todayStr = Qt.formatDate(now, "yyyy-MM-dd");
        const offset = (now.getDay() + 6) % 7;
        const thisMonday = new Date(now);
        thisMonday.setDate(now.getDate() - offset);
        const startMonday = new Date(thisMonday);
        startMonday.setDate(thisMonday.getDate() - (count - 1) * 7);

        const thr = (GlobalConfig.focus.streakThresholdMins || 30) * 60;
        const goal = Math.max(thr, (GlobalConfig.focus.dailyGoalMins || 240) * 60);

        const weeks = [];
        let prevMonth = -1;
        for (let w = 0; w < count; w++) {
            const wDays = [];
            let monthLabel = "";
            for (let d = 0; d < 7; d++) {
                const cur = new Date(startMonday);
                cur.setDate(startMonday.getDate() + w * 7 + d);
                const k = Qt.formatDate(cur, "yyyy-MM-dd");
                const dayObj = days[k];
                const secs = dayObj ? Math.round(dayObj.focusSecs || 0) : 0;
                const sessions = dayObj ? Math.round(dayObj.sessions || 0) : 0;
                const restDay = !!(dayObj && dayObj.restDay);
                const isFuture = k > todayStr;
                const isToday = k === todayStr;

                if (w === 0 && d === 0) {
                    monthLabel = Qt.formatDate(cur, "MMM");
                    prevMonth = cur.getMonth();
                } else if (cur.getMonth() !== prevMonth && (d === 0 || cur.getDate() === 1)) {
                    if (monthLabel === "") {
                        monthLabel = Qt.formatDate(cur, "MMM");
                        prevMonth = cur.getMonth();
                    }
                }

                let level = 0;
                if (!isFuture && secs > 0) {
                    if (secs >= goal) level = 4;
                    else if (secs >= goal * 0.5) level = 3;
                    else if (secs >= thr) level = 2;
                    else level = 1;
                }

                wDays.push({
                    key: k,
                    dateLabel: Qt.formatDate(cur, "ddd, MMM d"),
                    secs: secs,
                    sessions: sessions,
                    restDay: restDay,
                    isFuture: isFuture,
                    isToday: isToday,
                    level: level
                });
            }
            weeks.push({
                weekIndex: w,
                monthLabel: monthLabel,
                days: wDays
            });
        }
        return weeks;
    }

    function dayState(key: string): string {
        summaryRevision;
        void todayKey;
        let today = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (key > today) return "future";
        let d = days[key];
        let thr = (GlobalConfig.focus.streakThresholdMins || 30) * 60;
        let secs = d ? (d.focusSecs || 0) : 0;
        if (secs >= thr) return "done";
        if (d && d.restDay) return "rest";
        if (key === today) return "today";
        return "missed";
    }

    function fmt(secs: int): string {
        if (!secs || secs <= 0) return "0m";
        if (secs < 60) return `${secs}s`;
        let totalMins = Math.floor(secs / 60);
        let h = Math.floor(totalMins / 60);
        let m = totalMins % 60;
        if (h > 0) {
            return h + "h " + (m < 10 ? "0" + m : m) + "m";
        }
        return m + "m";
    }

    function flush(): void {
        if (!ready || corrupt || !dirty) return;
        saveImmediate();
    }

    function loadData(rawText: string): void {
        try {
            if (!rawText || rawText.trim() === "") {
                days = {};
                pauseOnSleep = false;
                lastSubject = "";
                countdowns = defaultCountdowns();
                ready = true;
                mergePending();
                refreshWeekNames();
                revision++;
                summaryRevision++;
                return;
            }
            let data = JSON.parse(rawText);
            if (typeof data !== "object" || data === null) throw new Error("Invalid ledger format");
            days = data.days || {};
            pauseOnSleep = !!data.pauseOnSleep;
            lastSubject = typeof data.lastSubject === "string" ? data.lastSubject : "";
            if (Array.isArray(data.countdowns)) {
                countdowns = data.countdowns;
            } else {
                countdowns = defaultCountdowns();
                dirty = true;
            }
            ready = true;
            if (!backedUp) {
                backupFile.setText(rawText);
                backedUp = true;
            }
            mergePending();
            refreshWeekNames();
            revision++;
            summaryRevision++;
            if (dirty) saveDebounce.restart();
        } catch (e) {
            ready = false;
            corrupt = true;
            Toaster.toast(Tr.tr("Focus Ledger Error"), Tr.tr("Failed to read focus data. Ledger locked to prevent overwrite."), "error", Toast.Error);
        }
    }

    function mergePending(): void {
        if (!ready) return;
        let changed = false;
        if (pendingSessions > 0) {
            if (!days[todayKey]) {
                days[todayKey] = { focusSecs: 0, sessions: 0, restDay: false, subjects: {} };
            }
            days[todayKey].sessions = (days[todayKey].sessions || 0) + pendingSessions;
            pendingSessions = 0;
            changed = true;
        }
        for (let s in pendingSecs) {
            if (pendingSecs.hasOwnProperty(s)) {
                let secs = pendingSecs[s];
                if (secs > 0) {
                    if (!days[todayKey]) {
                        days[todayKey] = { focusSecs: 0, sessions: 0, restDay: false, subjects: {} };
                    }
                    if (!days[todayKey].subjects) {
                        days[todayKey].subjects = {};
                    }
                    days[todayKey].focusSecs = (days[todayKey].focusSecs || 0) + secs;
                    days[todayKey].subjects[s] = (days[todayKey].subjects[s] || 0) + secs;
                    changed = true;
                }
            }
        }
        pendingSecs = {};
        if (changed) {
            dirty = true;
            revision++;
            summaryRevision++;
            saveDebounce.restart();
        }
    }

    function saveImmediate(): void {
        if (!ready || corrupt || !dirty) return;
        let data = {
            version: 1,
            pauseOnSleep: pauseOnSleep,
            lastSubject: lastSubject,
            countdowns: countdowns,
            days: days
        };
        ledgerFile.setText(JSON.stringify(data, null, 2));
        dirty = false;
    }

    Timer {
        id: saveDebounce
        interval: 400
        repeat: false
        onTriggered: root.saveImmediate()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.checkTodayKey()
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refreshWeekNames()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Paths.state]);
    }

    Component.onDestruction: root.flush()
}
