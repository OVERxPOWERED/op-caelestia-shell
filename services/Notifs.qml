pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded
    property var appRules: ({})
    property list<var> knownApps: []

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    function isAppEnabled(appName: string): bool {
        if (!appName)
            return true;
        const rule = root.appRules[appName];
        return rule ? rule.enabled !== false : true;
    }

    function isAppPopups(appName: string): bool {
        if (!appName)
            return true;
        const rule = root.appRules[appName];
        return rule ? rule.popups !== false : true;
    }

    function setAppEnabled(appName: string, enabled: bool): void {
        if (!appName)
            return;
        const updated = Object.assign({}, root.appRules);
        const existing = updated[appName] || {};
        updated[appName] = Object.assign({}, existing, { enabled });
        root.appRules = updated;
        appRulesFile.setText(JSON.stringify(updated, null, 2));
        updateKnownApps();
    }

    function setAppPopups(appName: string, popups: bool): void {
        if (!appName)
            return;
        const updated = Object.assign({}, root.appRules);
        const existing = updated[appName] || {};
        updated[appName] = Object.assign({}, existing, { popups });
        root.appRules = updated;
        appRulesFile.setText(JSON.stringify(updated, null, 2));
        updateKnownApps();
    }

    function updateKnownApps(): void {
        const appMap = {};

        for (const notif of root.list) {
            const name = (notif.appName || notif.notification?.appName || "").trim();
            if (!name)
                continue;
            if (!appMap[name]) {
                const icon = (notif.appIcon || notif.notification?.appIcon || "").trim();
                appMap[name] = {
                    appName: name,
                    appIcon: icon,
                    count: 1
                };
            } else {
                appMap[name].count++;
                if (!appMap[name].appIcon && notif.appIcon)
                    appMap[name].appIcon = notif.appIcon;
            }
        }

        for (const name of Object.keys(root.appRules)) {
            if (!appMap[name]) {
                appMap[name] = {
                    appName: name,
                    appIcon: root.appRules[name]?.appIcon || "",
                    count: 0
                };
            }
        }

        const result = Object.values(appMap).map(app => {
            const rule = root.appRules[app.appName] || {};
            return {
                appName: app.appName,
                appIcon: app.appIcon || rule.appIcon || "",
                count: app.count,
                enabled: rule.enabled !== false,
                popups: rule.popups !== false
            };
        });

        result.sort((a, b) => a.appName.localeCompare(b.appName));
        root.knownApps = result;
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                }))))
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const name = (notif.appName || "").trim();
            if (name && !root.isAppEnabled(name)) {
                notif.close();
                return;
            }

            const canPopup = root.shouldShowPopup() && (name ? root.isAppPopups(name) : true);
            const comp = notifComp.createObject(root, {
                popup: canPopup,
                notification: notif
            });
            root.list = [comp, ...root.list];
            root.updateKnownApps();
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            let data = [];
            try {
                const content = text().trim();
                if (content.length > 0)
                    data = JSON.parse(content);
            } catch (e) {
                console.warn("Failed to parse notifications JSON:", e);
                data = [];
            }
            if (Array.isArray(data)) {
                for (const notif of data) {
                    if (!notif)
                        continue;
                    const properties = Object.assign({}, notif);

                    // Backwards compatibility for old notifications
                    if (properties.notificationId === undefined && properties.id !== undefined)
                        properties.notificationId = properties.id;

                    delete properties.id;
                    root.list.push(notifComp.createObject(root, properties));
                }
                root.list.sort((a, b) => (b?.time ?? 0) - (a?.time ?? 0));
            }
            root.loaded = true;
            root.updateKnownApps();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                root.updateKnownApps();
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    FileView {
        id: appRulesFile

        printErrors: false
        path: `${Paths.state}/notif-apps.json`
        onLoaded: {
            try {
                const content = text().trim();
                if (content.length > 0)
                    root.appRules = JSON.parse(content);
            } catch (e) {
                root.appRules = ({});
            }
            root.updateKnownApps();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.appRules = ({});
                root.updateKnownApps();
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
