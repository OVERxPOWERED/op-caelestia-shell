pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    property bool authenticated: false
    property bool syncing: false
    property string accountEmail: ""
    property var calendars: []
    property var eventsMap: ({})
    property date lastSyncTime: new Date(0)
    property int syncInterval: 1800 // 30 minutes in seconds
    property string statusMessage: ""

    readonly property string scriptPath: `${Quickshell.shellDir}/utils/scripts/gcal_sync.py`

    function dateToKey(d: date): string {
        if (!d) return "";
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function hasEvents(d: date): bool {
        const key = dateToKey(d);
        const list = eventsMap[key];
        return Boolean(list && list.length > 0);
    }

    function getEvents(d: date): var {
        const key = dateToKey(d);
        return eventsMap[key] || [];
    }

    function sync(): void {
        if (syncing) return;
        syncing = true;
        statusMessage = Tr.tr("Syncing events...");
        syncProc.running = true;
    }

    function checkStatus(): void {
        statusProc.running = true;
    }

    function login(clientId = "", clientSecret = "", credentialsFile = ""): void {
        if (syncing) return;
        syncing = true;
        statusMessage = Tr.tr("Waiting for Google authentication in browser...");

        const args = ["python3", root.scriptPath, "login"];
        if (credentialsFile && credentialsFile.length > 0) {
            args.push("--credentials-file", credentialsFile);
        } else if (clientId && clientSecret) {
            args.push("--client-id", clientId, "--client-secret", clientSecret);
        }

        loginProc.command = args;
        loginProc.running = true;
    }

    function logout(): void {
        logoutProc.running = true;
    }

    function toggleCalendar(calendarId: string, enabled: bool): void {
        toggleCalProc.command = [
            "python3", root.scriptPath, "toggle-calendar",
            "--calendar-id", calendarId,
            "--enabled", enabled ? "true" : "false"
        ];
        toggleCalProc.running = true;
    }

    // Load cached events from disk
    FileView {
        id: eventsStorage

        printErrors: false
        path: `${Paths.cache}/calendar/events.json`

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && typeof data === "object") {
                    root.eventsMap = data.events || {};
                    if (data.account) {
                        root.accountEmail = data.account;
                        root.authenticated = true;
                    }
                    if (data.lastSyncEpoch) {
                        root.lastSyncTime = new Date(data.lastSyncEpoch * 1000);
                    }
                    if (data.calendars && Array.isArray(data.calendars)) {
                        root.calendars = data.calendars;
                    }
                }
            } catch (err) {
                console.warn(lc, `Failed to parse calendar events cache: ${err}`);
            }
        }

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.warn(lc, `Failed to load calendar events cache: ${err}`);
            }
        }
    }

    // Load cached calendar list
    FileView {
        id: calendarsStorage

        printErrors: false
        path: `${Paths.cache}/calendar/calendars.json`

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && Array.isArray(data.calendars)) {
                    root.calendars = data.calendars;
                }
            } catch (err) {
                console.warn(lc, `Failed to parse calendars cache: ${err}`);
            }
        }
    }

    // Watch tokens to quickly reflect login / logout state
    FileView {
        id: tokensStorage

        printErrors: false
        path: `${Paths.config}/calendar/tokens.json`

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.authenticated = Boolean(data && data.refresh_token);
                if (data && data.email) {
                    root.accountEmail = data.email;
                }
            } catch (err) {
                root.authenticated = false;
            }
        }

        onLoadFailed: {
            root.authenticated = false;
        }
    }

    // Status Process
    Process {
        id: statusProc

        command: ["python3", root.scriptPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    root.authenticated = Boolean(res.authenticated);
                    root.accountEmail = res.email || "";
                    if (res.calendars && Array.isArray(res.calendars))
                        root.calendars = res.calendars;
                } catch (e) {
                    // Ignore parse error
                }
            }
        }
    }

    // Sync Process
    Process {
        id: syncProc

        command: ["python3", root.scriptPath, "sync"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.syncing = false;
                try {
                    const res = JSON.parse(text);
                    if (res.status === "success") {
                        root.authenticated = true;
                        root.lastSyncTime = new Date();
                        root.statusMessage = Tr.tr("Events up to date");
                        eventsStorage.reload();
                        calendarsStorage.reload();
                    } else {
                        root.statusMessage = res.message || Tr.tr("Sync failed");
                        if (res.message && res.message.indexOf("Not authenticated") !== -1) {
                            root.authenticated = false;
                        }
                    }
                } catch (e) {
                    root.statusMessage = Tr.tr("Sync error");
                }
            }
        }
        onExited: code => {
            root.syncing = false;
            if (code !== 0 && root.statusMessage === Tr.tr("Syncing events...")) {
                root.statusMessage = Tr.tr("Sync process failed");
            }
        }
    }

    // Login Process
    Process {
        id: loginProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.syncing = false;
                try {
                    const res = JSON.parse(text);
                    if (res.status === "success") {
                        root.authenticated = true;
                        root.accountEmail = res.email || "";
                        root.statusMessage = Tr.tr("Authenticated successfully");
                        Toaster.toast(Tr.tr("Google Calendar Connected"), Tr.tr("Logged in as %1").arg(res.email), "calendar_month");
                        eventsStorage.reload();
                        calendarsStorage.reload();
                        tokensStorage.reload();
                    } else {
                        root.statusMessage = res.message || Tr.tr("Authentication failed");
                        Toaster.toast(Tr.tr("Authentication Failed"), res.message || "", "error");
                    }
                } catch (e) {
                    root.statusMessage = Tr.tr("Authentication error");
                }
            }
        }
        onExited: code => {
            root.syncing = false;
            if (code !== 0 && root.authenticated === false) {
                root.statusMessage = Tr.tr("Login process exited or cancelled");
            }
        }
    }

    // Logout Process
    Process {
        id: logoutProc

        command: ["python3", root.scriptPath, "logout"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.authenticated = false;
                root.accountEmail = "";
                root.eventsMap = ({});
                root.calendars = [];
                root.statusMessage = Tr.tr("Logged out");
                Toaster.toast(Tr.tr("Google Calendar Disconnected"), Tr.tr("Your account has been unlinked"), "logout");
                tokensStorage.reload();
                eventsStorage.reload();
                calendarsStorage.reload();
            }
        }
    }

    // Toggle Calendar Process
    Process {
        id: toggleCalProc

        stdout: StdioCollector {
            onStreamFinished: {
                calendarsStorage.reload();
                eventsStorage.reload();
            }
        }
    }

    // Periodic Background Sync Timer
    Timer {
        id: syncTimer

        interval: Math.max(60, root.syncInterval) * 1000
        repeat: true
        running: root.authenticated && !root.syncing

        onTriggered: root.sync()
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.calendar"
        defaultLogLevel: LoggingCategory.Info
    }

    Component.onCompleted: {
        root.checkStatus();
    }
}
