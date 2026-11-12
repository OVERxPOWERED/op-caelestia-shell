pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    property bool showInstructions: true
    property bool autoClearSearch: true
    property bool autoFocusSearch: true
    property int maxHistory: 1000
    property int imageCardHeight: 116

    function clearCache() {
        clearCacheProc.running = true;
    }

    function wipeHistory() {
        wipeHistoryProc.running = true;
    }

    function save() {
        try {
            const data = {
                showInstructions: root.showInstructions,
                autoClearSearch: root.autoClearSearch,
                autoFocusSearch: root.autoFocusSearch,
                maxHistory: root.maxHistory,
                imageCardHeight: root.imageCardHeight
            };
            settingsFile.setText(JSON.stringify(data, null, 2));
        } catch (e) {
            console.error("Failed to save clipboard settings:", e);
        }
    }

    FileView {
        id: settingsFile

        path: `${Paths.state}/clipboard-settings.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data) {
                    if (typeof data.showInstructions === "boolean")
                        root.showInstructions = data.showInstructions;
                    if (typeof data.autoClearSearch === "boolean")
                        root.autoClearSearch = data.autoClearSearch;
                    if (typeof data.autoFocusSearch === "boolean")
                        root.autoFocusSearch = data.autoFocusSearch;
                    if (typeof data.maxHistory === "number")
                        root.maxHistory = data.maxHistory;
                    if (typeof data.imageCardHeight === "number")
                        root.imageCardHeight = data.imageCardHeight;
                }
            } catch (e) {
                // Ignore parse errors on first run
            }
        }
    }

    Process {
        id: clearCacheProc
        command: ["sh", "-c", "rm -rf ~/.cache/cliphist/thumbnails/*"]
    }

    Process {
        id: wipeHistoryProc
        command: ["cliphist", "wipe"]
    }
}
