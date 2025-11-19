pragma Singleton

import QtQuick

/**
 * PaneRegistry
 * 
 * Centralized registry for Control Center panes. This singleton provides a single
 * source of truth for pane metadata (id, label, icon, component), eliminating
 * the need for manual index management and making adding/removing panes trivial.
 * 
 * Usage:
 * - Panes.qml: Dynamically creates panes from registry
 * - Session.qml: Derives panes list from registry
 * - NavRail.qml: Uses registry for navigation items
 */
QtObject {
    id: root

    /**
     * Pane metadata structure:
     * - id: Unique identifier for the pane (string)
     * - label: Display label for the pane (string)
     * - icon: Material icon name (string)
     * - component: Component path relative to controlcenter module (string)
     */
    readonly property list<QtObject> panes: [
        QtObject {
            readonly property string id: "network"
            readonly property string label: "network"
            readonly property string icon: "router"
            readonly property string component: "network/NetworkingPane.qml"
        },
        QtObject {
            readonly property string id: "bluetooth"
            readonly property string label: "bluetooth"
            readonly property string icon: "settings_bluetooth"
            readonly property string component: "bluetooth/BtPane.qml"
        },
        QtObject {
            readonly property string id: "audio"
            readonly property string label: "audio"
            readonly property string icon: "volume_up"
            readonly property string component: "audio/AudioPane.qml"
        },
        QtObject {
            readonly property string id: "appearance"
            readonly property string label: "appearance"
            readonly property string icon: "palette"
            readonly property string component: "appearance/AppearancePane.qml"
        },
        QtObject {
            readonly property string id: "taskbar"
            readonly property string label: "taskbar"
            readonly property string icon: "task_alt"
            readonly property string component: "taskbar/TaskbarPane.qml"
        },
        QtObject {
            readonly property string id: "launcher"
            readonly property string label: "launcher"
            readonly property string icon: "apps"
            readonly property string component: "launcher/LauncherPane.qml"
        }
    ]

    /**
     * Get the count of registered panes
     */
    readonly property int count: panes.length

    /**
     * Get pane labels as a list of strings
     * Useful for Session.qml's panes property
     */
    readonly property var labels: {
        const result = [];
        for (let i = 0; i < panes.length; i++) {
            result.push(panes[i].label);
        }
        return result;
    }

    /**
     * Get pane metadata by index
     * @param index The index of the pane
     * @return The pane metadata object or null if index is out of bounds
     */
    function getByIndex(index: int): QtObject {
        if (index >= 0 && index < panes.length) {
            return panes[index];
        }
        return null;
    }

    /**
     * Get pane index by label
     * @param label The label to search for
     * @return The index of the pane or -1 if not found
     */
    function getIndexByLabel(label: string): int {
        for (let i = 0; i < panes.length; i++) {
            if (panes[i].label === label) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Get pane metadata by label
     * @param label The label to search for
     * @return The pane metadata object or null if not found
     */
    function getByLabel(label: string): QtObject {
        const index = getIndexByLabel(label);
        return getByIndex(index);
    }

    /**
     * Get pane metadata by id
     * @param id The id to search for
     * @return The pane metadata object or null if not found
     */
    function getById(id: string): QtObject {
        for (let i = 0; i < panes.length; i++) {
            if (panes[i].id === id) {
                return panes[i];
            }
        }
        return null;
    }
}

