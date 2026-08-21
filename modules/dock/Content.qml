pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.launcher.services
import qs.services
import QtQml.Models

Item {
    id: root

    required property ScreenState screenState
    required property var panels

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property int itemSize: Tokens.sizes.launcher.itemHeight * 1.2
    readonly property int iconSize: itemSize * 0.7

    property bool editMode: false
    readonly property bool contextMenuOpen: contextMenu.expanded
    readonly property real contextMenuHeight: contextMenu.expanded ? contextMenu.menuHeight + padding * 2 : 0

    property var updateMenuContext: null

    onToplevelsByEntryIdChanged: {
        if (updateMenuContext) updateMenuContext();
    }

    onRunningOnlyAppsChanged: {
        if (updateMenuContext) updateMenuContext();
    }

    onContextMenuOpenChanged: {
        if (!contextMenuOpen) updateMenuContext = null;
    }

    // Map: entryId -> [toplevels] for pinned app instance tracking
    readonly property var toplevelsByEntryId: {
        const toplevels = Hypr.toplevels.values;
        const map = {};
        for (const t of toplevels) {
            const cls = t.lastIpcObject?.class;
            if (!cls) continue;
            const entry = DesktopEntries.heuristicLookup(cls);
            const entryId = entry?.id;
            if (!entryId) continue;
            if (!map[entryId]) map[entryId] = [];
            map[entryId].push(t);
        }
        return map;
    }

    // Running apps NOT in the pinned list, grouped by class
    readonly property var runningOnlyApps: {
        const toplevels = Hypr.toplevels.values;
        const pinnedIds = GlobalConfig.dock.pinnedApps;
        const classMap = {};

        for (const t of toplevels) {
            const cls = t.lastIpcObject?.class;
            if (!cls) continue;
            if (!classMap[cls]) classMap[cls] = [];
            classMap[cls].push(t);
        }

        const result = [];
        for (const [cls, tls] of Object.entries(classMap)) {
            const entry = DesktopEntries.heuristicLookup(cls);
            const entryId = entry?.id;
            if (entryId && pinnedIds.includes(entryId)) continue;
            result.push({ className: cls, toplevels: tls, entry: entry });
        }
        return result;
    }

    // Whether the dock has any visible content (pinned or running apps)
    readonly property bool hasContent: GlobalConfig.dock.pinnedApps.length > 0 || runningOnlyApps.length > 0

    onEditModeChanged: {
        if (!editMode) {
            if (typeof visualModel !== "undefined" && visualModel.items) {
                let arr = [];
                for (let i = 0; i < visualModel.items.count; i++) {
                    arr.push(visualModel.items.get(i).model.modelData);
                }
                GlobalConfig.dock.pinnedApps = arr;
            }
        }
    }

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2

    // ── Helpers ──────────────────────────────────────────────────────

    function getAppEntry(id: string) {
        if (!id) return null;
        for (let i = 0; i < Apps.list.length; ++i) {
            if (Apps.list[i].id === id) {
                return Apps.list[i].entry;
            }
        }
        return null;
    }

    function focusWindow(toplevel): void {
        const addr = toplevel.address;
        const wsId = toplevel.workspace?.id;

        // First switch to the workspace (proven pattern)
        if (wsId !== undefined) {
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.focus({ workspace = "${wsId}" })`
                : `workspace ${wsId}`);
        }

        // Then focus the specific window
        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.window.focus({ window = "address:0x${addr}" })`
            : `focuswindow address:0x${addr}`);

        root.screenState.dock = false;
    }

    function closeWindow(toplevel): void {
        const addr = toplevel.address;
        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.window.close({ window = "address:0x${addr}" })`
            : `closewindow address:0x${addr}`);
    }

    // ── Context menu builders ───────────────────────────────────────

    function openContextMenuAt(sourceItem: Item, mouseX: real, mouseY: real, items: var): void {
        if (!contextMenu.parent) return;
        const pos = sourceItem.mapToItem(contextMenu.parent, mouseX, mouseY);

        // Clamp menu X to dock bounds so it stays within the input region
        const dockLeft = root.mapToItem(contextMenu.parent, 0, 0).x;
        const dockRight = root.mapToItem(contextMenu.parent, root.width, 0).x;
        const menuWidth = 260;
        const clampedX = Math.max(dockLeft, Math.min(pos.x, dockRight - menuWidth));

        contextMenu.open(clampedX, pos.y, items);
    }

    function openPinnedAppMenu(sourceItem: Item, mouseX: real, mouseY: real, appId: string, index: int): void {
        const generateItems = () => {
            const instances = toplevelsByEntryId[appId] ?? [];
            const items = [];

            if (instances.length > 0) {
                items.push({ text: qsTr("New Instance"), icon: "add", action: () => {
                    const entry = getAppEntry(appId);
                    if (entry) Apps.launch(entry);
                    root.screenState.dock = false;
                }});

                for (let i = 0; i < instances.length; i++) {
                    const t = instances[i];
                    const title = t.title || t.lastIpcObject?.class || qsTr("Window");
                    items.push({ text: title, icon: "open_in_new", action: () => {
                        focusWindow(t);
                    }, closeAction: () => {
                        closeWindow(t);
                    }});
                }

                items.push({ separator: true });

                if (instances.length === 1) {
                    items.push({ text: qsTr("Close"), icon: "close", action: () => {
                        closeWindow(instances[0]);
                    }});
                } else {
                    items.push({ text: qsTr("Close All (%1)").arg(instances.length), icon: "close", action: () => {
                        for (const t of instances) closeWindow(t);
                    }});
                }

                items.push({ separator: true });
            }

            items.push({ text: qsTr("Remove"), icon: "remove_circle_outline", action: () => {
                let newApps = [...GlobalConfig.dock.pinnedApps];
                newApps.splice(index, 1);
                GlobalConfig.dock.pinnedApps = newApps;
            }});
            items.push({ text: qsTr("Edit"), icon: "edit", action: () => {
                root.editMode = true;
            }});
            items.push({ text: qsTr("Add App"), icon: "add_circle_outline", action: () => {
                root.screenState.launcherPickCallback = (app) => {
                    let arr = [...GlobalConfig.dock.pinnedApps];
                    if (!arr.includes(app.id)) {
                        arr.push(app.id);
                        GlobalConfig.dock.pinnedApps = arr;
                    }
                };
                root.screenState.launcher = true;
                root.screenState.dock = false;
            }});

            return items;
        };

        root.updateMenuContext = () => {
            if (contextMenu.expanded) {
                contextMenu.menuItems = generateItems();
            }
        };

        openContextMenuAt(sourceItem, mouseX, mouseY, generateItems());
    }

    function openRunningAppMenu(sourceItem: Item, mouseX: real, mouseY: real, className: string): void {
        const generateItems = () => {
            let currentToplevels = [];
            for (let i = 0; i < runningOnlyApps.length; i++) {
                if (runningOnlyApps[i].className === className) {
                    currentToplevels = runningOnlyApps[i].toplevels;
                    break;
                }
            }

            if (currentToplevels.length === 0) return null;

            const items = [];
            const entry = DesktopEntries.heuristicLookup(className);

            items.push({ text: qsTr("New Instance"), icon: "add", action: () => {
                if (entry) entry.execute();
                root.screenState.dock = false;
            }});

            for (let i = 0; i < currentToplevels.length; i++) {
                const t = currentToplevels[i];
                const title = t.title || className;
                items.push({ text: title, icon: "open_in_new", action: () => {
                    focusWindow(t);
                }, closeAction: () => {
                    closeWindow(t);
                }});
            }

            items.push({ separator: true });

            if (currentToplevels.length === 1) {
                items.push({ text: qsTr("Close"), icon: "close", action: () => {
                    closeWindow(currentToplevels[0]);
                }});
            } else {
                items.push({ text: qsTr("Close All (%1)").arg(currentToplevels.length), icon: "close", action: () => {
                    for (const t of currentToplevels) closeWindow(t);
                }});
            }

            items.push({ separator: true });

            items.push({ text: qsTr("Pin to Dock"), icon: "push_pin", action: () => {
                if (entry) {
                    let arr = [...GlobalConfig.dock.pinnedApps];
                    if (!arr.includes(entry.id) && arr.length < GlobalConfig.dock.maxSlots) {
                        arr.push(entry.id);
                        GlobalConfig.dock.pinnedApps = arr;
                    }
                }
            }});

            return items;
        };

        root.updateMenuContext = () => {
            if (contextMenu.expanded) {
                const newItems = generateItems();
                if (newItems === null) {
                    contextMenu.close();
                } else {
                    contextMenu.menuItems = newItems;
                }
            }
        };

        const initialItems = generateItems();
        if (initialItems) {
            openContextMenuAt(sourceItem, mouseX, mouseY, initialItems);
        }
    }

    function openEmptySpaceMenu(sourceItem: Item, mouseX: real, mouseY: real): void {
        const items = [];

        items.push({ text: qsTr("Add App"), icon: "add_circle_outline", action: () => {
            root.screenState.launcherPickCallback = (app) => {
                let arr = [...GlobalConfig.dock.pinnedApps];
                if (!arr.includes(app.id)) {
                    arr.push(app.id);
                    GlobalConfig.dock.pinnedApps = arr;
                }
            };
            root.screenState.launcher = true;
            root.screenState.dock = false;
        }});
        items.push({ text: qsTr("Edit Dock"), icon: "edit", action: () => {
            root.editMode = true;
        }});

        openContextMenuAt(sourceItem, mouseX, mouseY, items);
    }

    // ── Connections & background handlers ────────────────────────────

    Connections {
        target: root.screenState
        function onDockChanged() {
            if (!root.screenState.dock) {
                root.editMode = false;
                contextMenu.close();
            }
        }
    }

    // Long-press on empty dock space to enter edit mode
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressAndHold: root.editMode = true
        z: -1
    }

    // Right-click on empty dock space
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            root.openEmptySpaceMenu(root, mouse.x, mouse.y);
        }
        z: -1
    }

    // ── Main layout ─────────────────────────────────────────────────

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        // ── Pinned apps ─────────────────────────────────────────────

        ListView {
            id: listView
            width: count * root.itemSize + Math.max(0, count - 1) * Tokens.spacing.medium
            height: root.itemSize
            orientation: ListView.Horizontal
            spacing: Tokens.spacing.medium
            interactive: false

            displaced: Transition {
                Anim { properties: "x,y" }
            }

            model: DelegateModel {
                id: visualModel
                model: GlobalConfig.dock.pinnedApps

                delegate: DropArea {
                    id: delegateRoot
                    width: root.itemSize
                    height: root.itemSize

                    required property string modelData
                    required property int index

                    readonly property var entry: root.getAppEntry(modelData)
                    readonly property var instances: root.toplevelsByEntryId[modelData] ?? []
                    readonly property int instanceCount: instances.length

                    keys: ["dockItem"]

                    onEntered: (drag) => {
                        if (drag.source.visualIndex !== undefined) {
                            let from = drag.source.visualIndex;
                            let to = delegateRoot.DelegateModel.itemsIndex;
                            if (from !== to) {
                                visualModel.items.move(from, to);
                            }
                        }
                    }

                    Item {
                        id: contentItem
                        width: root.itemSize
                        height: root.itemSize

                        Drag.active: dragHandler.active
                        Drag.source: contentItem
                        Drag.keys: ["dockItem"]
                        property int visualIndex: delegateRoot.DelegateModel.itemsIndex

                        DragHandler {
                            id: dragHandler
                            enabled: root.editMode
                            target: contentItem
                            xAxis.enabled: true
                            yAxis.enabled: false
                        }

                        states: [
                            State {
                                when: dragHandler.active
                                ParentChange {
                                    target: contentItem
                                    parent: listView
                                }
                                AnchorChanges {
                                    target: contentItem
                                    anchors.horizontalCenter: undefined
                                    anchors.verticalCenter: undefined
                                }
                                PropertyChanges {
                                    target: contentItem
                                    opacity: 0.8
                                    z: 10
                                }
                            }
                        ]

                        // Item background
                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer
                        }

                        StateLayer {
                            radius: Tokens.rounding.large
                            anchors.fill: parent
                            onClicked: {
                                if (root.editMode) return;
                                if (delegateRoot.instanceCount > 0) {
                                    root.focusWindow(delegateRoot.instances[0]);
                                } else if (entry) {
                                    Apps.launch(entry);
                                    root.screenState.dock = false;
                                }
                            }
                            onPressAndHold: root.editMode = true
                        }

                        // Right-click for context menu
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                root.openPinnedAppMenu(contentItem, mouse.x, mouse.y, delegateRoot.modelData, delegateRoot.index);
                            }
                        }

                        IconImage {
                            asynchronous: true
                            source: Quickshell.iconPath(entry?.icon, "image-missing")
                            width: root.iconSize
                            height: root.iconSize
                            anchors.centerIn: parent
                        }

                        // Running instance count badge
                        Rectangle {
                            visible: delegateRoot.instanceCount > 0 && !root.editMode
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: -2
                            anchors.rightMargin: -2
                            width: Math.max(badgeText.implicitWidth + 8, height)
                            height: badgeText.implicitHeight + 4
                            radius: height / 2
                            color: Colours.palette.m3tertiary
                            border.width: 2
                            border.color: Colours.palette.m3surface
                            z: 5

                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: delegateRoot.instanceCount
                                color: Colours.palette.m3onTertiary
                                font: Tokens.font.label.small
                            }
                        }

                        // Edit mode overlay (remove button)
                        Rectangle {
                            visible: root.editMode
                            width: root.iconSize * 0.4
                            height: width
                            radius: width / 2
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -width / 4
                            anchors.rightMargin: -width / 4
                            z: 10

                            color: Colours.palette.m3error
                            border.width: 2
                            border.color: Colours.palette.m3surface

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "remove"
                                color: Colours.palette.m3onError
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let newApps = [...GlobalConfig.dock.pinnedApps];
                                    newApps.splice(index, 1);
                                    GlobalConfig.dock.pinnedApps = newApps;
                                }
                            }
                        }

                        // Subtle wobble animation in edit mode
                        SequentialAnimation on rotation {
                            running: root.editMode && !dragHandler.active
                            loops: Animation.Infinite
                            Anim { from: 0; to: 3; duration: 150; type: Anim.DefaultEffects }
                            Anim { from: 3; to: -3; duration: 300; type: Anim.DefaultEffects }
                            Anim { from: -3; to: 0; duration: 150; type: Anim.DefaultEffects }
                        }
                    }
                }
            }
        }

        // ── Divider between pinned and running-only apps ────────────

        Rectangle {
            visible: GlobalConfig.dock.pinnedApps.length > 0 && root.runningOnlyApps.length > 0
            width: 2
            height: root.itemSize * 0.5
            y: (root.itemSize - height) / 2
            radius: 1
            color: Colours.palette.m3outlineVariant
            opacity: 0.6
        }

        // ── Running-only apps (not pinned) ──────────────────────────

        Repeater {
            model: root.runningOnlyApps

            delegate: Item {
                id: runningItem

                required property var modelData
                required property int index

                readonly property string className: modelData.className
                readonly property var toplevels: modelData.toplevels
                readonly property var appEntry: modelData.entry

                width: root.itemSize
                height: root.itemSize

                // Item background
                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer
                }

                StateLayer {
                    radius: Tokens.rounding.large
                    anchors.fill: parent
                    onClicked: {
                        if (root.editMode) return;
                        root.focusWindow(runningItem.toplevels[0]);
                    }
                    onPressAndHold: root.editMode = true
                }

                // Right-click for context menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        root.openRunningAppMenu(runningItem, mouse.x, mouse.y, runningItem.className);
                    }
                }

                IconImage {
                    asynchronous: true
                    source: Quickshell.iconPath(runningItem.appEntry?.icon ?? runningItem.className, "image-missing")
                    width: root.iconSize
                    height: root.iconSize
                    anchors.centerIn: parent
                }

                // Running instance count badge
                Rectangle {
                    visible: runningItem.toplevels.length > 0
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: -2
                    anchors.rightMargin: -2
                    width: Math.max(runBadgeText.implicitWidth + 8, height)
                    height: runBadgeText.implicitHeight + 4
                    radius: height / 2
                    color: Colours.palette.m3tertiary
                    border.width: 2
                    border.color: Colours.palette.m3surface
                    z: 5

                    StyledText {
                        id: runBadgeText
                        anchors.centerIn: parent
                        text: runningItem.toplevels.length
                        color: Colours.palette.m3onTertiary
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        // ── Add button (only when dock is completely empty) ─────────

        Item {
            width: root.itemSize
            height: root.itemSize
            visible: !root.hasContent && !root.editMode

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: {
                    root.screenState.launcherPickCallback = (app) => {
                        let arr = [...GlobalConfig.dock.pinnedApps];
                        if (!arr.includes(app.id)) {
                            arr.push(app.id);
                            GlobalConfig.dock.pinnedApps = arr;
                        }
                    };
                    root.screenState.launcher = true;
                    root.screenState.dock = false;
                }
            }

            MaterialIcon {
                text: "add"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.extraLarge
                anchors.centerIn: parent
            }
        }

        // ── Edit button (only when dock is empty, or in edit mode) ──

        Item {
            width: root.itemSize
            height: root.itemSize
            visible: !root.hasContent || root.editMode

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: root.editMode = !root.editMode
            }

            MaterialIcon {
                text: root.editMode ? "check" : "edit"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.large
                anchors.centerIn: parent
            }
        }
    }

    // ── Context menu ────────────────────────────────────────────────

    DockContextMenu {
        id: contextMenu
    }
}
