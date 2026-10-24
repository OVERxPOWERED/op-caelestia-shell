pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

Singleton {
    id: root

    // Tab state: 0 = Workspaces, 1 = Special, 2 = All Windows
    property int activeTab: 0
    property string searchQuery: ""
    property int selectedCardIndex: 0
    property int selectedWindowIndex: 0

    // Layout mode: false = Carousel (linear), true = Grid
    property bool gridMode: false

    // Drag-and-drop state across workspaces
    property var draggingWindow: null
    property var draggingWorkspace: null
    property real dragGlobalX: 0
    property real dragGlobalY: 0
    property string dragTitle: ""
    property string dragIcon: ""
    readonly property bool isDragging: draggingWindow !== null || draggingWorkspace !== null
    property int dropTargetWsId: -1

    property int dragOriginIndex: -1
    property int dragTargetIndex: -1
    property var dragInitialWorkspaces: []

    property var customWorkspaceOrder: []
    property real lastSwapTime: 0

    readonly property int nextAvailableWsId: {
        const allWsIds = Hypr.workspaces.values
            .filter(ws => ws && !ws.name.startsWith("special:"))
            .map(ws => ws.id);
        return (allWsIds.length > 0 ? Math.max(...allWsIds) : 0) + 1;
    }

    function startWindowDrag(toplevel, title, icon, x, y): void {
        draggingWorkspace = null;
        draggingWindow = toplevel;
        dragTitle = title || "";
        dragIcon = icon || "";
        dragGlobalX = x;
        dragGlobalY = y;
        dropTargetWsId = -1;
        dragOriginIndex = -1;
        dragTargetIndex = -1;
        dragInitialWorkspaces = [];
    }

    function startWorkspaceDrag(ws, title, x, y, originIndex): void {
        draggingWindow = null;
        draggingWorkspace = ws;
        dragTitle = title || "";
        dragIcon = "";
        dragGlobalX = x;
        dragGlobalY = y;
        dropTargetWsId = -1;

        const normalWs = getNormalWorkspaces(null);
        dragInitialWorkspaces = normalWs.map(w => w.id);
        dragOriginIndex = (originIndex !== undefined && originIndex >= 0)
            ? originIndex
            : dragInitialWorkspaces.indexOf(ws ? ws.id : -1);
        dragTargetIndex = dragOriginIndex;
    }

    function updateDrag(x, y): void {
        dragGlobalX = x;
        dragGlobalY = y;
    }

    function cancelDrag(): void {
        draggingWindow = null;
        draggingWorkspace = null;
        dropTargetWsId = -1;
        dragOriginIndex = -1;
        dragTargetIndex = -1;
        dragInitialWorkspaces = [];
    }

    function finishDrag(): void {
        if (draggingWindow) {
            if (dropTargetWsId >= 0) {
                moveWindowToWorkspace(draggingWindow, dropTargetWsId);
            } else {
                createWorkspaceWithWindow(draggingWindow);
            }
            cancelDrag();
        } else if (draggingWorkspace) {
            const origin = dragOriginIndex;
            const target = dragTargetIndex;
            const initialList = [...dragInitialWorkspaces];

            cancelDrag();

            if (origin >= 0 && target >= 0 && origin !== target && initialList.length > 0) {
                // SICE / SHIFT: remove from origin, insert at target
                const finalOrder = [...initialList];
                const movedItem = finalOrder.splice(origin, 1)[0];
                finalOrder.splice(target, 0, movedItem);

                applyWorkspaceOrderToHyprland(finalOrder);
            }
        } else {
            cancelDrag();
        }
    }

    function getVisualIndex(cardIndex: int, originIndex: int, targetIndex: int, isDraggingWs: bool): int {
        if (!isDraggingWs || originIndex < 0 || targetIndex < 0 || originIndex === targetIndex) {
            return cardIndex;
        }
        if (cardIndex === originIndex) {
            return targetIndex;
        }
        if (originIndex > targetIndex) {
            // Dragging left (e.g. from 2 to 0): cards between target and origin shift right (+1)
            if (cardIndex >= targetIndex && cardIndex < originIndex) {
                return cardIndex + 1;
            }
        } else if (originIndex < targetIndex) {
            // Dragging right (e.g. from 0 to 2): cards between origin and target shift left (-1)
            if (cardIndex > originIndex && cardIndex <= targetIndex) {
                return cardIndex - 1;
            }
        }
        return cardIndex;
    }

    function applyWorkspaceOrderToHyprland(order: var): void {
        if (!order || order.length === 0) {
            return;
        }

        const moves = [];
        let anyChanged = false;

        for (let i = 0; i < order.length; i++) {
            const oldId = order[i];
            const newId = i + 1;
            if (oldId !== newId) {
                anyChanged = true;
            }
            const toplevels = Hypr.toplevels.values.filter(t => t && t.workspace && t.workspace.id === oldId);
            moves.push({
                oldId: oldId,
                newId: newId,
                toplevels: toplevels,
                tempId: 90000 + i + 1
            });
        }

        if (!anyChanged) {
            return;
        }

        // Preferred: renumber the workspaces themselves. Windows stay where they are in their
        // workspace, so their layouts are untouched, and it is a single batched request instead
        // of one move per window (which re-tiled every window and flooded the shell with events).
        const inOrder = new Set(order);
        const collides = order.some((oldId, i) => oldId !== i + 1 && !inOrder.has(i + 1) && Hypr.workspaces.values.some(w => w && w.id === i + 1));
        if (Hypr.usingLua && !collides) {
            const change = (ws, id) => `eval hl.dispatch(hl.dsp.workspace.change_id({ workspace = "${ws}", id = ${id} }))`;
            const batch = [];
            for (const m of moves) {
                if (m.oldId !== m.newId)
                    batch.push(change(m.oldId, m.tempId));
            }
            for (const m of moves) {
                if (m.oldId !== m.newId)
                    batch.push(change(m.tempId, m.newId));
            }
            Hypr.extras.batchMessage(batch);
            // Hyprland does not announce a renumbering, so the shell's copy of the workspaces and
            // of each monitor's active workspace goes stale (the bar kept the old dot lit)
            refreshPasses = 0;
            reorderRefresh.restart();
            return;
        }

        const prevFocusedWsId = Hypr.focusedWorkspace?.id;
        let nextFocusedWsId = prevFocusedWsId;

        for (const m of moves) {
            if (m.oldId === prevFocusedWsId) {
                nextFocusedWsId = m.newId;
                break;
            }
        }

        // Phase 1: Move all windows of changing workspaces to temporary workspace IDs
        for (const m of moves) {
            if (m.oldId !== m.newId) {
                for (const t of m.toplevels) {
                    moveWindowToWorkspace(t, m.tempId);
                }
            }
        }

        // Phase 2: Move windows from temporary IDs to final sequential target IDs
        for (const m of moves) {
            if (m.oldId !== m.newId) {
                for (const t of m.toplevels) {
                    moveWindowToWorkspace(t, m.newId);
                }
            }
        }

        // Phase 3: Switch focus to the new ID of the previously focused workspace
        if (nextFocusedWsId !== undefined && nextFocusedWsId !== null) {
            focusWorkspace(nextFocusedWsId);
        }

        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
    }

    function createWorkspaceWithWindow(toplevel: HyprlandToplevel): void {
        if (!toplevel) return;

        const newWsId = root.nextAvailableWsId;

        let order = [...root.customWorkspaceOrder];
        if (order.length === 0) {
            const allWs = Hypr.workspaces.values.filter(w => w && !w.name.startsWith("special:"));
            allWs.sort((a, b) => a.id - b.id);
            order = allWs.map(w => w.id);
        }
        if (!order.includes(newWsId)) {
            order.push(newWsId);
            root.customWorkspaceOrder = [...order];
        }

        moveWindowToWorkspace(toplevel, newWsId);
    }

    property int refreshPasses

    Timer {
        id: reorderRefresh

        interval: 120
        repeat: true
        onTriggered: {
            // Workspaces first: monitors and windows refer to them by id
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
            Hyprland.refreshToplevels();
            if (++root.refreshPasses >= 3)
                stop();
        }
    }

    function swapWorkspaces(wsIdA: int, wsIdB: int, force = false): void {
        if (wsIdA === wsIdB) return;
        const now = Date.now();
        if (!force && (now - lastSwapTime < 280)) return;
        lastSwapTime = now;

        let order = [...root.customWorkspaceOrder];
        if (order.length === 0) {
            const currentList = getNormalWorkspaces(null);
            order = currentList.map(w => w.id);
        }
        if (!order.includes(wsIdA)) order.push(wsIdA);
        if (!order.includes(wsIdB)) order.push(wsIdB);

        const idxA = order.indexOf(wsIdA);
        const idxB = order.indexOf(wsIdB);
        if (idxA >= 0 && idxB >= 0) {
            const temp = order[idxA];
            order[idxA] = order[idxB];
            order[idxB] = temp;
            root.customWorkspaceOrder = [...order];
        }
    }

    readonly property list<string> tabNames: [
        qsTr("Workspaces"),
        qsTr("Special"),
        qsTr("All Windows")
    ]

    function reset(): void {
        searchQuery = "";
        selectedCardIndex = 0;
        selectedWindowIndex = 0;
        customWorkspaceOrder = [];
        cancelDrag();
    }

    // Normal workspaces sorted by ID: only workspaces with >= 1 window or currently focused
    function getNormalWorkspaces(monitor: HyprlandMonitor): var {
        const monId = monitor?.id ?? -1;
        const focusedId = Hypr.focusedWorkspace?.id ?? -1;

        const list = Hypr.workspaces.values.filter(ws => {
            if (!ws || ws.name.startsWith("special:"))
                return false;
            if (monId >= 0 && ws.monitor && ws.monitor.id !== monId)
                return false;

            const hasWindows = getToplevelsForWorkspace(ws.id).length > 0;
            const isFocused = ws.id === focusedId;

            return hasWindows || isFocused;
        });

        // Ensure currently focused workspace is included if it matches monitor and not special
        if (Hypr.focusedWorkspace && !Hypr.focusedWorkspace.name.startsWith("special:")) {
            const fw = Hypr.focusedWorkspace;
            const fwMonId = fw.monitor?.id ?? -1;
            if (monId < 0 || fwMonId < 0 || fwMonId === monId) {
                if (!list.some(ws => ws.id === fw.id)) {
                    list.push(fw);
                }
            }
        }

        // Sort by custom order if set, otherwise numerically by ID
        if (root.customWorkspaceOrder.length > 0) {
            list.sort((a, b) => {
                const idxA = root.customWorkspaceOrder.indexOf(a.id);
                const idxB = root.customWorkspaceOrder.indexOf(b.id);
                if (idxA >= 0 && idxB >= 0) return idxA - idxB;
                if (idxA >= 0) return -1;
                if (idxB >= 0) return 1;
                return a.id - b.id;
            });
        } else {
            list.sort((a, b) => a.id - b.id);
        }
        return list;
    }

    // Special / scratchpad workspaces with >= 1 window
    function getSpecialWorkspaces(): var {
        const list = Hypr.workspaces.values.filter(ws => {
            if (!ws || !ws.name.startsWith("special:"))
                return false;
            return getToplevelsForWorkspace(ws.id).length > 0;
        });
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }

    // Get all toplevel windows for a given workspace
    function getToplevelsForWorkspace(wsId: int): var {
        return Hypr.toplevels.values.filter(t => t && t.workspace && t.workspace.id === wsId);
    }

    // Get all toplevel windows across all workspaces, filtered by search query
    function getAllToplevels(query: string): var {
        const q = (query ?? "").trim().toLowerCase();
        return Hypr.toplevels.values.filter(t => {
            if (!t) return false;
            if (!q) return true;

            const title = (t.title ?? "").toLowerCase();
            const cls = (t.lastIpcObject?.class ?? t.lastIpcObject?.initialClass ?? "").toLowerCase();
            const wsName = (t.workspace?.name ?? "").toLowerCase();

            return title.includes(q) || cls.includes(q) || wsName.includes(q);
        });
    }

    // Focus a workspace and close overview
    function focusWorkspace(wsId: int, callback: var): void {
        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.focus({ workspace = "${wsId}" })`
            : `workspace ${wsId}`);
        if (callback) callback();
    }

    // Toggle/Focus a special workspace
    function toggleSpecialWorkspace(wsName: string, callback: var): void {
        const cleanName = wsName.startsWith("special:") ? wsName.slice("special:".length) : wsName;
        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.workspace.toggle_special("${cleanName}")`
            : `togglespecialworkspace ${cleanName}`);
        if (callback) callback();
    }

    // Focus a specific window
    function focusWindow(toplevel: HyprlandToplevel, callback: var): void {
        if (!toplevel) return;
        const addr = toplevel.address;
        const wsId = toplevel.workspace?.id;
        if (wsId !== undefined) {
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.focus({ workspace = "${wsId}" })`
                : `workspace ${wsId}`);
        }
        if (addr) {
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.focus({ window = "address:0x${addr}" })`
                : `focuswindow address:0x${addr}`);
        }
        if (callback) callback();
    }

    // Close a specific window
    function closeWindow(toplevel: HyprlandToplevel): void {
        if (!toplevel) return;
        const addr = toplevel.address;
        if (addr) {
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.window.close({ window = "address:0x${addr}" })`
                : `closewindow address:0x${addr}`);
        }
    }

    // Move a window to a destination workspace
    function moveWindowToWorkspace(toplevel: HyprlandToplevel, wsId: int): void {
        if (!toplevel) return;
        const addr = toplevel.address;
        if (addr) {
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.window.move({ window = "address:0x${addr}", workspace = "${wsId}", silent = true })`
                : `movetoworkspacesilent ${wsId},address:0x${addr}`);
        }
    }

    // Create a new workspace (next highest integer or 1)
    function createNewWorkspace(callback: var): void {
        const normalWs = Hypr.workspaces.values.filter(ws => ws && !ws.name.startsWith("special:"));
        let nextId = 1;
        if (normalWs.length > 0) {
            const maxId = Math.max(...normalWs.map(w => w.id));
            nextId = maxId + 1;
        }
        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.focus({ workspace = "${nextId}" })`
            : `workspace ${nextId}`);
        if (callback) callback();
    }
}
