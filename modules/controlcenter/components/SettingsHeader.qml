pragma ComponentBehavior: Bound

import qs.components
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * SettingsHeader
 * 
 * Reusable header component for settings panes. Displays a large icon and title
 * in a consistent format across all settings screens.
 * 
 * Usage:
 * ```qml
 * SettingsHeader {
 *     icon: "router"
 *     title: qsTr("Network Settings")
 * }
 * ```
 */
Item {
    id: root

    /**
     * Material icon name to display
     */
    required property string icon

    /**
     * Title text to display
     */
    required property string title

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font.pointSize: Appearance.font.size.large
            font.bold: true
        }
    }
}

