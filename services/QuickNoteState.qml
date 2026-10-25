pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    property string notesDir: Paths.home + "/Documents/Notes"
    property string currentFileName: "ToDo.txt"
    readonly property string currentFilePath: notesDir + "/" + currentFileName

    property list<string> availableFiles: ["ToDo.txt"]
    property list<string> customTags: ["todo", "study", "ideas", "work", "scratch"]
    property var fileTags: ({}) // { fileName: [tag1, tag2] }
    property string activeTagFilter: "all"

    property string activeAppClass: ""
    property string activeAppTitle: ""
    property string activeTimestamp: ""
    property string activeIcon: ""

    readonly property string configFile: Paths.config + "/quicknote.json"

    function getFilteredFiles(): var {
        if (!activeTagFilter || activeTagFilter === "all") {
            return availableFiles;
        }
        return availableFiles.filter(f => {
            const tags = fileTags[f] || [];
            return tags.includes(activeTagFilter);
        });
    }

    function addCustomTag(tag: string): void {
        const clean = (tag ?? "").trim().replace(/^#/, "").toLowerCase();
        if (!clean || customTags.includes(clean)) return;
        customTags = [...customTags, clean];
        saveConfig();
    }

    function removeCustomTag(tag: string): void {
        const clean = (tag ?? "").trim().replace(/^#/, "").toLowerCase();
        customTags = customTags.filter(t => t !== clean);
        // Clean from fileTags
        const updated = Object.assign({}, fileTags);
        let changed = false;
        for (const f in updated) {
            if (Array.isArray(updated[f]) && updated[f].includes(clean)) {
                updated[f] = updated[f].filter(t => t !== clean);
                changed = true;
            }
        }
        if (changed) fileTags = updated;
        if (activeTagFilter === clean) activeTagFilter = "all";
        saveConfig();
    }

    function toggleTagForCurrentFile(tag: string): void {
        toggleTagForFile(currentFileName, tag);
    }

    function toggleTagForFile(fileName: string, tag: string): void {
        if (!fileName) return;
        const clean = (tag ?? "").trim().replace(/^#/, "").toLowerCase();
        const updated = Object.assign({}, fileTags);
        const curTags = updated[fileName] ? [...updated[fileName]] : [];
        const idx = curTags.indexOf(clean);
        if (idx >= 0) {
            curTags.splice(idx, 1);
        } else {
            curTags.push(clean);
        }
        updated[fileName] = curTags;
        fileTags = updated;
        saveConfig();
    }

    function getTagsForFile(fileName: string): var {
        return fileTags[fileName] || [];
    }

    function createNewNote(fileName: string, initialTag = ""): void {
        let name = (fileName ?? "").trim();
        if (!name) return;
        if (!name.endsWith(".txt") && !name.endsWith(".md")) {
            name += ".txt";
        }
        createProc.exec(["touch", `${root.notesDir}/${name}`]);
        if (!availableFiles.includes(name)) {
            availableFiles = [...availableFiles, name];
        }
        if (initialTag && initialTag !== "all") {
            toggleTagForFile(name, initialTag);
        }
        currentFileName = name;
        refreshFiles();
    }

    function captureContext(): void {
        const toplevel = Hypr.activeToplevel;
        if (toplevel && toplevel.title) {
            root.activeAppTitle = toplevel.title;
            root.activeAppClass = toplevel.initialClass || toplevel.appId || "";
            const entry = DesktopEntries.heuristicLookup(root.activeAppClass);
            root.activeIcon = entry?.icon ? Quickshell.iconPath(entry.icon, "") : "";
        } else {
            root.activeAppTitle = "Desktop";
            root.activeAppClass = "";
            root.activeIcon = "";
        }
        root.activeTimestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm");
        refreshFiles();
    }

    function refreshFiles(): void {
        filesProc.exec(["sh", "-c", `mkdir -p "${root.notesDir}" && ls -1 "${root.notesDir}" 2>/dev/null | grep -E '\\.(txt|md)$' || echo "ToDo.txt"`]);
    }

    function openInEditor(fileName: string): void {
        const target = fileName ? `${root.notesDir}/${fileName}` : root.currentFilePath;
        cmdProc.exec(["foot", "-a", "nano-scratch", "nano", target]);
    }

    function saveConfig(): void {
        const data = {
            customTags: root.customTags,
            fileTags: root.fileTags,
            notesDir: root.notesDir
        };
        cfgFile.setText(JSON.stringify(data, null, 4));
    }

    FileView {
        id: cfgFile
        path: root.configFile

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.customTags && Array.isArray(data.customTags)) {
                    root.customTags = data.customTags;
                }
                if (data.fileTags && typeof data.fileTags === "object") {
                    root.fileTags = data.fileTags;
                }
                if (data.notesDir) {
                    root.notesDir = data.notesDir;
                }
            } catch (e) {
                console.warn("[QuickNoteState] Failed to parse config JSON:", e);
            }
        }

        onLoadFailed: {
            root.saveConfig();
        }
    }

    Process {
        id: cmdProc
    }

    Process {
        id: createProc
    }

    Process {
        id: filesProc

        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.trim().split("\n").map(f => f.trim()).filter(f => f.length > 0);
                if (list.length > 0)
                    root.availableFiles = list;
            }
        }
    }

    Component.onCompleted: {
        refreshFiles();
    }
}
