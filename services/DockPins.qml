pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config

// Unpins dock apps that have been uninstalled.
//
// byId and heuristicLookup also find entries hidden from the launcher, so only an app with
// no desktop entry at all is removed. Nothing is removed until the app list has loaded, and
// checks wait for it to settle because package updates rewrite many .desktop files.
Singleton {
    id: root

    function prune(): void {
        if (DesktopEntries.applications.values.length === 0)
            return;

        const pinned = GlobalConfig.dock.pinnedApps;
        const kept = pinned.filter(id => DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id));
        if (kept.length === pinned.length)
            return;

        console.log("[dock] unpinning uninstalled apps:", pinned.filter(id => !kept.includes(id)).join(", "));
        GlobalConfig.dock.pinnedApps = kept;
        if (typeof GlobalConfig.save === "function")
            GlobalConfig.save();
    }

    Timer {
        id: timer

        interval: 5000
        running: true
        onTriggered: root.prune()
    }

    Connections {
        function onValuesChanged(): void {
            timer.restart();
        }

        target: DesktopEntries.applications
    }

    Connections {
        function onPinnedAppsChanged(): void {
            timer.restart();
        }

        target: GlobalConfig.dock
    }
}
