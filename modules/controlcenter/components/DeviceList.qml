pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

/**
 * DeviceList
 * 
 * A reusable base component for displaying lists of devices/networks with a standardized
 * structure. Provides a header with action buttons, title/subtitle, and a scrollable list
 * with customizable delegates.
 * 
 * This component eliminates duplication across WirelessList, EthernetList, and Bluetooth DeviceList
 * by providing a common structure while allowing full customization of headers and delegates.
 * 
 * Usage:
 * ```qml
 * DeviceList {
 *     session: root.session
 *     title: qsTr("Networks (%1)").arg(Nmcli.networks.length)
 *     description: qsTr("All available WiFi networks")
 *     model: ScriptModel {
 *         values: [...Nmcli.networks].sort(...)
 *     }
 *     activeItem: session.network.active
 *     onItemSelected: (item) => {
 *         session.network.active = item;
 *     }
 *     headerComponent: Component {
 *         RowLayout {
 *             // Custom header buttons
 *         }
 *     }
 *     delegate: Component {
 *         // Custom delegate for each item
 *     }
 * }
 * ```
 */
ColumnLayout {
    id: root

    property Session session: null
    property var model: null
    property Component delegate: null
    
    property string title: ""
    property string description: ""
    property var activeItem: null
    property Component headerComponent: null
    property Component titleSuffix: null
    property bool showHeader: true
    
    signal itemSelected(var item)

    spacing: Appearance.spacing.small

    // Header with action buttons (optional)
    Loader {
        id: headerLoader
        
        Layout.fillWidth: true
        sourceComponent: root.headerComponent
        visible: root.headerComponent !== null && root.showHeader
    }

    // Title and description row
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: root.headerComponent ? 0 : 0
        spacing: Appearance.spacing.small
        visible: root.title !== "" || root.description !== ""

        StyledText {
            visible: root.title !== ""
            text: root.title
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Loader {
            sourceComponent: root.titleSuffix
            visible: root.titleSuffix !== null
        }

        Item {
            Layout.fillWidth: true
        }
    }
    
    // Expose view for access from parent components
    property alias view: view

    // Description text
    StyledText {
        visible: root.description !== ""
        Layout.fillWidth: true
        text: root.description
        color: Colours.palette.m3outline
    }

    // List view
    StyledListView {
        id: view

        Layout.fillWidth: true
        // Use contentHeight to show all items without estimation
        implicitHeight: contentHeight

        model: root.model
        delegate: root.delegate

        spacing: Appearance.spacing.small / 2
        interactive: false  // Disable individual scrolling - parent pane handles it
        clip: false  // Don't clip - let parent handle scrolling
    }
}

