pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        {
            label: qsTr("Appearance"),
            icon: "palette",
            description: qsTr("Customise the look and feel of your desktop")
        },
        {
            label: qsTr("Taskbar"),
            icon: "dock_to_bottom",
            description: qsTr("Configure your taskbar appearance and behavior")
        },
        {
            label: qsTr("Launcher"),
            icon: "apps",
            description: qsTr("Customize application launcher settings")
        },
        {
            label: qsTr("Dashboard"),
            icon: "dashboard",
            description: qsTr("Configure dashboard widgets and layout")
        },
        {
            label: qsTr("Sidebar"),
            icon: "side_navigation",
            description: qsTr("Sidebar panel settings")
        },
        {
            label: qsTr("Utilities"),
            icon: "handyman",
            description: qsTr("Quick access utilities and tools")
        },
        {
            label: qsTr("Notifications"),
            icon: "notifications",
            description: qsTr("Manage notification settings and behavior")
        },
        {
            label: qsTr("Session"),
            icon: "account_circle",
            description: qsTr("User session and power menu settings")
        },
        {
            label: qsTr("Lockscreen"),
            icon: "lock",
            description: qsTr("Lock screen appearance and security")
        },
        {
            label: qsTr("Display"),
            icon: "monitor",
            title: "Display",
            description: qsTr("Monitor configuration and display settings")
        },
        {
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Network connections and settings")
        },
        {
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("Sound devices and volume control")
        },
        {
            label: qsTr("Bluetooth"),
            icon: "bluetooth",
            description: qsTr("Bluetooth device management")
        },
        {
            label: qsTr("Location"),
            icon: "location_on",
            description: qsTr("Location access and privacy")
        },
        {
            label: qsTr("Screen recorder"),
            icon: "screen_record",
            description: qsTr("Screen recording settings")
        },
        {
            label: qsTr("Power"),
            icon: "power_settings_new",
            description: qsTr("Power management and battery settings")
        },
        {
            label: qsTr("Plugins"),
            icon: "extension",
            description: qsTr("Manage and configure plugins")
        },
        {
            label: qsTr("Hooks"),
            icon: "link",
            description: qsTr("System hooks and automation")
        },
        {
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information and credits")
        },
        {
            label: qsTr("Updates"),
            icon: "update",
            description: qsTr("System updates and changelog")
        }
    ]
}
