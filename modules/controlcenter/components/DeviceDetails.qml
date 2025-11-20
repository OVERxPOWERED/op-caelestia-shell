pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * DeviceDetails
 * 
 * A reusable base component for displaying device/network details with a standardized
 * structure. Provides a header, connection status section, and flexible sections for
 * device-specific information.
 * 
 * This component eliminates duplication across WirelessDetails, EthernetDetails, and Bluetooth Details
 * by providing a common structure while allowing full customization of sections.
 * 
 * Usage:
 * ```qml
 * DeviceDetails {
 *     session: root.session
 *     device: session.network.active
 *     headerComponent: Component {
 *         ConnectionHeader {
 *             icon: "wifi"
 *             title: device?.ssid ?? ""
 *         }
 *     }
 *     sections: [
 *         Component {
 *             // Connection status section
 *         },
 *         Component {
 *             // Properties section
 *         }
 *     ]
 * }
 * ```
 */
Item {
    id: root

    required property Session session
    property var device: null
    
    property Component headerComponent: null
    property list<Component> sections: []
    
    // Optional: Custom content to insert after header but before sections
    property Component topContent: null
    
    // Optional: Custom content to insert after all sections
    property Component bottomContent: null

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Appearance.spacing.normal

        // Header component (e.g., ConnectionHeader or SettingsHeader)
        Loader {
            id: headerLoader
            
            Layout.fillWidth: true
            sourceComponent: root.headerComponent
            visible: root.headerComponent !== null
        }

        // Top content (optional)
        Loader {
            id: topContentLoader
            
            Layout.fillWidth: true
            sourceComponent: root.topContent
            visible: root.topContent !== null
        }

        // Sections
        Repeater {
            model: root.sections
            
            Loader {
                Layout.fillWidth: true
                sourceComponent: modelData
            }
        }

        // Bottom content (optional)
        Loader {
            id: bottomContentLoader
            
            Layout.fillWidth: true
            sourceComponent: root.bottomContent
            visible: root.bottomContent !== null
        }
    }
}

