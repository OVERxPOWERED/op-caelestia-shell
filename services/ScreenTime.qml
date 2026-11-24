pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.services
import qs.utils

Singleton {
    id: root

    property bool ready: false
    property bool corrupt: false
    property int revision: 0
    property int liveTick: 0
    property string todayKey: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string selectedKey: todayKey
    property bool strictShield: false
    property int retentionDays: 30
    property var days: ({})
    property var distractions: ["discord", "vesktop", "steam", "youtube"]
    property var limits: ({})
    property var notifiedLimitsToday: ({})
    property string currentAppClass: ""
    property string lastNudgedApp: ""
    property double lastNudgedAt: 0
    property bool dirty: false
    property bool backedUp: false
    property bool sessionLocked: false
    property bool systemSleeping: false
    property bool dpmsAsleep: false
    property double _dpmsOffAt: 0

    function setDpmsAsleep(asleep: bool): void {
        dpmsAsleep = asleep;
        if (asleep)
            _dpmsOffAt = Date.now();
    }

    readonly property string activeAppClass: {
        const top = Hypr.activeToplevel;
        if (!top) return "";
        const ipc = top.lastIpcObject;
        const cls = (ipc?.class || ipc?.initialClass || "").trim().toLowerCase();
        return cls;
    }

    readonly property bool screenAwake: {
        if (sessionLocked || systemSleeping || dpmsAsleep)
            return false;
        const mon = Hypr.focusedMonitor;
        if (mon && mon.lastIpcObject && mon.lastIpcObject.dpmsStatus === false)
            return false;
        const mons = Hypr.monitors?.values;
        if (mons && mons.length > 0) {
            let anyAwake = false;
            for (let i = 0; i < mons.length; i++) {
                if (mons[i]?.lastIpcObject?.dpmsStatus !== false) {
                    anyAwake = true;
                    break;
                }
            }
            if (!anyAwake)
                return false;
        }
        return true;
    }

    readonly property int todayTotalSecs: {
        liveTick;
        revision;
        return dayTotalSecs(todayKey);
    }

    readonly property int selectedTotalSecs: {
        liveTick;
        revision;
        return dayTotalSecs(selectedKey);
    }

    readonly property int weekTotalSecs: {
        liveTick;
        revision;
        let t = 0;
        const keys = last7DaysKeys();
        for (let i = 0; i < keys.length; i++) {
            t += dayTotalSecs(keys[i]);
        }
        return t;
    }

    readonly property int dailyAvgSecs: {
        liveTick;
        revision;
        const keys = last7DaysKeys();
        let activeDays = 0;
        let t = 0;
        for (let i = 0; i < keys.length; i++) {
            const s = dayTotalSecs(keys[i]);
            if (s > 0) {
                activeDays++;
                t += s;
            }
        }
        return activeDays > 0 ? Math.round(t / activeDays) : 0;
    }

    readonly property FileView backupFile: FileView {
        path: `${Paths.state}/screentime.json.bak`
        printErrors: false
    }

    readonly property FileView storeFile: FileView {
        path: `${Paths.state}/screentime.json`
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: root.loadData(text())
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.days = {};
                root.ready = true;
                root.revision++;
            } else {
                root.ready = false;
            }
        }
    }

    function checkTodayKey(): void {
        const k = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (k !== todayKey) {
            todayKey = k;
            if (selectedKey === "")
                selectedKey = k;
            pruneOldDays();
            notifiedLimitsToday = {};
            revision++;
        }
    }

    function pruneOldDays(): void {
        if (!days) return;
        const now = new Date();
        const cutoff = new Date(now.getTime() - retentionDays * 86400000);
        const cutoffKey = Qt.formatDate(cutoff, "yyyy-MM-dd");
        let pruned = false;
        for (const k in days) {
            if (days.hasOwnProperty(k)) {
                if (k < cutoffKey) {
                    delete days[k];
                    pruned = true;
                }
            }
        }
        if (pruned) {
            dirty = true;
        }
    }

    function isIgnoredApp(appClass: string): bool {
        if (!appClass) return true;
        const low = appClass.trim().toLowerCase();
        return low === "" || low.includes("quickshell") || low.includes("caelestia");
    }

    function sanitizeDays(): void {
        if (!days) return;
        let cleaned = false;
        for (const k in days) {
            if (!days.hasOwnProperty(k)) continue;
            const dayObj = days[k];
            if (!dayObj || !dayObj.apps) continue;
            let sum = 0;
            for (const app in dayObj.apps) {
                if (!dayObj.apps.hasOwnProperty(app)) continue;
                if (isIgnoredApp(app)) {
                    delete dayObj.apps[app];
                    cleaned = true;
                } else {
                    sum += Math.round(dayObj.apps[app] || 0);
                }
            }
            if (dayObj.totalSecs !== sum) {
                dayObj.totalSecs = sum;
                cleaned = true;
            }
        }
        if (cleaned) {
            dirty = true;
        }
    }

    function appName(appClass: string): string {
        if (!appClass) return "";
        const entry = DesktopEntries.heuristicLookup(appClass);
        if (entry && entry.name) return entry.name;
        let clean = appClass;
        const dotIdx = clean.lastIndexOf(".");
        if (dotIdx !== -1 && dotIdx < clean.length - 1) {
            clean = clean.slice(dotIdx + 1);
        }
        return clean.split(/[-_]+/).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    function appIcon(appClass: string): string {
        if (!appClass) return "";
        return Icons.getAppIcon(appClass, "");
    }

    function fmt(secs: int): string {
        if (!secs || secs <= 0) return "0m";
        if (secs < 60) return "<1m";
        const totalMins = Math.floor(secs / 60);
        const h = Math.floor(totalMins / 60);
        const m = totalMins % 60;
        if (h > 0) {
            return `${h}h ${m}m`;
        }
        return `${m}m`;
    }

    function fmtShort(secs: int): string {
        if (!secs || secs <= 0) return "0m";
        if (secs < 60) return "<1m";
        const totalMins = Math.floor(secs / 60);
        const h = Math.floor(totalMins / 60);
        const m = totalMins % 60;
        if (h > 0) {
            return m > 0 ? `${h}h ${m}m` : `${h}h`;
        }
        return `${m}m`;
    }

    function dayAppCount(key: string): int {
        revision;
        liveTick;
        if (!key || !days || !days[key] || !days[key].apps) return 0;
        let n = 0;
        const appMap = days[key].apps;
        for (const app in appMap) {
            if (appMap.hasOwnProperty(app) && !root.isIgnoredApp(app) && Math.round(appMap[app] || 0) >= 1)
                n++;
        }
        return n;
    }

    function dayTotalSecs(key: string): int {
        if (!key || !days || !days[key]) return 0;
        return Math.round(days[key].totalSecs || 0);
    }

    function usageForDay(dayKey: string, topN: int): var {
        revision;
        liveTick;
        if (!dayKey || !days || !days[dayKey] || !days[dayKey].apps) return [];
        const appMap = days[dayKey].apps;
        const limit = (typeof topN === "number" && topN > 0) ? topN : 5;
        const list = [];
        for (const app in appMap) {
            if (appMap.hasOwnProperty(app) && !root.isIgnoredApp(app)) {
                const s = Math.round(appMap[app] || 0);
                if (s >= 1) {
                    list.push({
                        appClass: app,
                        seconds: s
                    });
                }
            }
        }
        list.sort((a, b) => b.seconds - a.seconds);
        return list.slice(0, limit);
    }

    function usageLastDays(daysCount: int): var {
        revision;
        liveTick;
        const result = [];
        if (!days) return result;
        const n = (typeof daysCount === "number" && daysCount > 0) ? daysCount : 7;
        for (let i = 0; i < n; i++) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const k = Qt.formatDate(d, "yyyy-MM-dd");
            const dayObj = days[k];
            if (dayObj && dayObj.apps) {
                for (const app in dayObj.apps) {
                    if (dayObj.apps.hasOwnProperty(app)) {
                        result.push({
                            day: k,
                            appClass: app,
                            seconds: Math.round(dayObj.apps[app] || 0)
                        });
                    }
                }
            }
        }
        return result;
    }

    function last7DaysKeys(): var {
        void todayKey;
        const now = new Date();
        const keys = [];
        const offset = (now.getDay() + 6) % 7; // Monday = 0, Sunday = 6
        const monday = new Date(now);
        monday.setDate(now.getDate() - offset);

        for (let i = 0; i < 7; i++) {
            const cur = new Date(monday);
            cur.setDate(monday.getDate() + i);
            keys.push(Qt.formatDate(cur, "yyyy-MM-dd"));
        }
        return keys;
    }

    function topAppsForDay(key: string, maxCount: int): var {
        revision;
        liveTick;
        if (!key || !days || !days[key] || !days[key].apps) return [];
        const appMap = days[key].apps;
        const total = dayTotalSecs(key);
        const limit = (typeof maxCount === "number" && maxCount > 0) ? maxCount : 6;

        const list = [];
        for (const app in appMap) {
            if (appMap.hasOwnProperty(app) && !root.isIgnoredApp(app)) {
                const s = Math.round(appMap[app] || 0);
                if (s > 0) {
                    list.push({
                        appClass: app,
                        name: root.appName(app),
                        icon: root.appIcon(app),
                        secs: s,
                        ratio: total > 0 ? Math.min(1.0, s / total) : 0,
                        limitMins: (limits && limits[app]) ? limits[app] : 0,
                        isDistraction: root.isDistraction(app)
                    });
                }
            }
        }
        list.sort((a, b) => b.secs - a.secs);
        return list.slice(0, limit);
    }

    function allKnownApps(): var {
        revision;
        const keys = last7DaysKeys();
        const usageMap = {};
        const appSet = new Set();

        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            const dayObj = days ? days[k] : null;
            if (dayObj && dayObj.apps) {
                for (const app in dayObj.apps) {
                    if (dayObj.apps.hasOwnProperty(app) && !root.isIgnoredApp(app)) {
                        const low = app.toLowerCase();
                        appSet.add(low);
                        usageMap[low] = (usageMap[low] || 0) + (dayObj.apps[app] || 0);
                    }
                }
            }
        }

        if (Array.isArray(distractions)) {
            for (let i = 0; i < distractions.length; i++) {
                if (distractions[i]) {
                    appSet.add(String(distractions[i]).toLowerCase());
                }
            }
        }

        if (limits && typeof limits === "object") {
            for (const l in limits) {
                if (limits.hasOwnProperty(l)) {
                    appSet.add(l.toLowerCase());
                }
            }
        }

        const list = [];
        appSet.forEach(app => {
            const s = Math.round(usageMap[app] || 0);
            list.push({
                appClass: app,
                name: root.appName(app),
                icon: root.appIcon(app),
                secs: s,
                weekSecs: s,
                limitMins: (limits && limits[app]) ? limits[app] : 0,
                isDistraction: root.isDistraction(app)
            });
        });

        list.sort((a, b) => b.secs - a.secs);
        return list;
    }

    function isDistraction(appClass: string): bool {
        if (!appClass || !Array.isArray(distractions)) return false;
        return distractions.indexOf(appClass.toLowerCase()) !== -1;
    }

    function toggleDistraction(appClass: string): void {
        if (!ready || corrupt || !appClass) return;
        const low = appClass.toLowerCase();
        const arr = Array.isArray(distractions) ? [...distractions] : [];
        const idx = arr.indexOf(low);
        if (idx !== -1) {
            arr.splice(idx, 1);
        } else {
            arr.push(low);
        }
        distractions = arr;
        dirty = true;
        revision++;
        saveDebounce.restart();
    }

    function setAppLimit(appClass: string, mins: int): void {
        if (!ready || corrupt || !appClass) return;
        const low = appClass.toLowerCase();
        const newLimits = Object.assign({}, limits);
        if (mins <= 0) {
            delete newLimits[low];
        } else {
            newLimits[low] = Math.round(mins);
        }
        limits = newLimits;
        dirty = true;
        revision++;
        saveDebounce.restart();
    }

    function appLimit(appClass: string): int {
        if (!appClass || !limits) return 0;
        return Math.round(limits[appClass.toLowerCase()] || 0);
    }

    function setStrictShield(on: bool): void {
        if (!ready || corrupt) return;
        strictShield = !!on;
        dirty = true;
        revision++;
        saveDebounce.restart();
    }

    function setRetentionDays(days: int): void {
        if (!ready || corrupt) return;
        retentionDays = Math.max(1, Math.round(days));
        dirty = true;
        revision++;
        pruneOldDays();
        saveDebounce.restart();
    }

    function clearHistory(): void {
        if (!ready || corrupt) return;
        days = {};
        notifiedLimitsToday = {};
        dirty = true;
        revision++;
        saveImmediate();
    }

    function loadData(rawText: string): void {
        try {
            if (!rawText || rawText.trim() === "") {
                days = {};
                ready = true;
                revision++;
                return;
            }
            const data = JSON.parse(rawText);
            if (typeof data !== "object" || data === null) throw new Error("Invalid screentime format");

            strictShield = !!data.strictShield;
            retentionDays = typeof data.retentionDays === "number" ? Math.max(1, Math.round(data.retentionDays)) : 30;
            distractions = Array.isArray(data.distractions) ? data.distractions.map(d => String(d).toLowerCase()) : ["discord", "vesktop", "steam", "youtube"];
            limits = (data.limits && typeof data.limits === "object") ? data.limits : {};
            days = (data.days && typeof data.days === "object") ? data.days : {};

            if (!backedUp) {
                backupFile.setText(rawText);
                backedUp = true;
            }
            pruneOldDays();
            sanitizeDays();
            ready = true;
            revision++;
            if (dirty) saveDebounce.restart();
        } catch (e) {
            ready = false;
            corrupt = true;
            Toaster.toast(Tr.tr("Screen Time Error"), Tr.tr("Failed to read screen time data. Store locked to prevent overwrite."), "error", Toast.Error);
        }
    }

    function saveImmediate(): void {
        if (!ready || corrupt || !dirty) return;
        const data = {
            version: 1,
            strictShield: strictShield,
            retentionDays: retentionDays,
            distractions: distractions,
            limits: limits,
            days: days
        };
        storeFile.setText(JSON.stringify(data, null, 2));
        dirty = false;
    }

    function flush(): void {
        if (!ready || corrupt || !dirty) return;
        saveImmediate();
    }

    onActiveAppClassChanged: {
        if (activeAppClass !== currentAppClass) {
            currentAppClass = activeAppClass;
            revision++;
        }
    }

    Connections {
        target: SessionManager

        function onAboutToSleep(): void {
            root.systemSleeping = true;
        }

        function onResumed(): void {
            root.systemSleeping = false;
            root.dpmsAsleep = false;
            Hyprland.refreshMonitors();
        }
    }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            root.checkTodayKey();
            root.liveTick++;

            if (root.dpmsAsleep && root.liveTick % 10 === 0) {
                if (Date.now() - root._dpmsOffAt > 1500) {
                    const mons = Hypr.monitors?.values;
                    if (mons && mons.some(m => m?.lastIpcObject?.dpmsStatus === true))
                        root.dpmsAsleep = false;
                }
                if (root.dpmsAsleep)
                    Hyprland.refreshMonitors();
            }

            const appClass = root.activeAppClass;
            if (!root.screenAwake || root.isIgnoredApp(appClass)) {
                return;
            }

            if (!root.ready || root.corrupt) return;

            if (!root.days[root.todayKey]) {
                root.days[root.todayKey] = {
                    totalSecs: 0,
                    apps: {}
                };
            }
            if (!root.days[root.todayKey].apps) {
                root.days[root.todayKey].apps = {};
            }

            root.days[root.todayKey].totalSecs = (root.days[root.todayKey].totalSecs || 0) + 1;
            root.days[root.todayKey].apps[appClass] = (root.days[root.todayKey].apps[appClass] || 0) + 1;
            root.dirty = true;

            if (root.liveTick % 5 === 0) {
                root.revision++;
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 400
        repeat: false
        onTriggered: root.saveImmediate()
    }

    Timer {
        id: saveTimer
        interval: 15000
        repeat: true
        running: root.dirty
        onTriggered: root.saveImmediate()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Paths.state]);
    }

    Component.onDestruction: root.flush()
}
