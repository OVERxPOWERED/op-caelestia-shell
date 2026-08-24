pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wi-Fi Hotspot")
    isSubPage: true

    property bool showPassword: false

    property bool savedFeedback: false

    Timer {
        id: savedTimer
        interval: 3000
        onTriggered: root.savedFeedback = false
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // 1. Master Hotspot Toggle
        ToggleRow {
            first: true
            last: true
            text: qsTr("Wi-Fi Hotspot")
            subtext: Hotspot.active
                ? qsTr("Broadcasting '%1' (%2 connected)").arg(Hotspot.ssid).arg(Hotspot.clientCount)
                : qsTr("Turn your device into an Access Point")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: Hotspot.active
            disabled: Hotspot.pending
            onToggled: Hotspot.toggle()
        }

        // Diagnostic / Error Banner if hotspot failed
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: Hotspot.lastError.length > 0 && !Hotspot.active
            color: Colours.palette.m3errorContainer
            implicitHeight: errLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: errLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "error"
                    color: Colours.palette.m3onErrorContainer
                    fontStyle: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Hotspot.lastError.includes("IP configuration") || Hotspot.lastError.includes("reserved")
                            ? qsTr("Missing DHCP Server (dnsmasq)")
                            : qsTr("Hotspot Activation Failed")
                        color: Colours.palette.m3onErrorContainer
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        text: Hotspot.lastError.includes("IP configuration") || Hotspot.lastError.includes("reserved")
                            ? qsTr("Run: sudo pacman -S dnsmasq to enable DHCP hotspot sharing.")
                            : Hotspot.lastError
                        color: Colours.palette.m3onErrorContainer
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // Saved Feedback Banner
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: root.savedFeedback
            color: Colours.palette.m3primaryContainer
            implicitHeight: savedLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: savedLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "check_circle"
                    color: Colours.palette.m3onPrimaryContainer
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Hotspot.active
                        ? qsTr("Settings saved! Restarting hotspot with new credentials...")
                        : qsTr("Settings saved successfully!")
                    color: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.body.small
                }
            }
        }

        // 2. Configuration Settings Section
        SectionHeader {
            text: qsTr("Hotspot Settings")
        }

        StyledTextField {
            id: ssidField
            Layout.fillWidth: true
            text: Hotspot.ssid
            placeholderText: qsTr("Hotspot Network Name (SSID)")
            supportingText: qsTr("The name visible to other devices")
            leadingIcon: "wifi_tethering"
            errorText: qsTr("SSID cannot be empty")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            onAccepted: passwordField.forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: passwordField
                Layout.fillWidth: true
                text: Hotspot.password
                placeholderText: qsTr("Password (at least 8 characters)")
                supportingText: qsTr("WPA2 / WPA3 security key")
                leadingIcon: "lock"
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                errorText: qsTr("Password must be at least 8 characters")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                onAccepted: saveBtn.clicked()
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                icon: root.showPassword ? "visibility_off" : "visibility"
                type: IconButton.Tonal
                isRound: true
                onClicked: root.showPassword = !root.showPassword
            }
        }

        SelectRow {
            id: bandSelect
            Layout.fillWidth: true
            first: true
            last: true
            label: qsTr("Frequency band")
            fallbackText: Hotspot.band === "a" ? qsTr("5 GHz (High Speed)") : qsTr("2.4 GHz (Standard / Long Range)")
            fallbackIcon: "cell_tower"

            menuItems: [
                MenuItem {
                    icon: "wifi"
                    text: qsTr("2.4 GHz (Standard / Long Range)")
                    onClicked: Hotspot.band = "bg"
                },
                MenuItem {
                    icon: "speed"
                    text: qsTr("5 GHz (High Speed)")
                    onClicked: Hotspot.band = "a"
                }
            ]
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small

            Item { Layout.fillWidth: true }

            IconTextButton {
                id: saveBtn
                text: root.savedFeedback ? qsTr("Saved!") : qsTr("Save & Apply")
                icon: root.savedFeedback ? "check" : "save"
                type: root.savedFeedback ? IconTextButton.Tonal : IconTextButton.Filled
                onClicked: {
                    const s = ssidField.text.trim();
                    const p = passwordField.text;
                    if (s.length === 0) {
                        ssidField.isError = true;
                        ssidField.forceActiveFocus();
                        return;
                    }
                    if (p.length < 8) {
                        passwordField.isError = true;
                        passwordField.forceActiveFocus();
                        return;
                    }
                    ssidField.isError = false;
                    passwordField.isError = false;
                    Hotspot.updateCredentials(s, p, Hotspot.band);
                    root.savedFeedback = true;
                    savedTimer.restart();
                    Toaster.toast(qsTr("Wi-Fi Hotspot"), qsTr("Hotspot settings updated to '%1'").arg(s), "wifi_tethering");
                }
            }
        }

        // 3. Connected Devices Section
        SectionHeader {
            text: qsTr("Connected Devices (%1)").arg(Hotspot.clientCount)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2
            visible: Hotspot.active && Hotspot.connectedClients.length > 0

            Repeater {
                model: Hotspot.connectedClients

                delegate: ConnectedRect {
                    required property var modelData
                    required property int index

                    first: index === 0
                    last: index === Hotspot.connectedClients.length - 1
                    Layout.fillWidth: true
                    implicitHeight: clientRow.implicitHeight + Tokens.padding.medium * 2

                    RowLayout {
                        id: clientRow
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "devices"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: modelData.ip || qsTr("Unknown Device")
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: `MAC: ${modelData.mac || ""}  •  ${modelData.state || "Active"}`
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // Empty state when no clients connected
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            visible: !Hotspot.active || Hotspot.connectedClients.length === 0
            implicitHeight: 72

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Hotspot.active ? qsTr("No devices connected yet") : qsTr("Hotspot is currently turned off")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }
            }
        }
    }
}
