pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "wifi"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Network settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("WiFi status")
        description: qsTr("General WiFi settings")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("WiFi enabled")
            checked: Network.wifiEnabled
            toggle.onToggled: {
                Network.enableWifi(checked);
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("Network information")
        description: qsTr("Current network connection")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("Connected network")
            value: Network.active ? Network.active.ssid : qsTr("Not connected")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Signal strength")
            value: Network.active ? qsTr("%1%").arg(Network.active.strength) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Security")
            value: Network.active ? (Network.active.isSecure ? qsTr("Secured") : qsTr("Open")) : qsTr("N/A")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("Frequency")
            value: Network.active ? qsTr("%1 MHz").arg(Network.active.frequency) : qsTr("N/A")
        }
    }
}

