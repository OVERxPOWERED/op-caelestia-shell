pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property string credentialsPath: ""
    property string clientIdText: ""
    property string clientSecretText: ""

    title: Tr.tr("Google Calendar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Account status
        SectionHeader {
            first: true
            text: Tr.tr("Account")
        }

        InfoRow {
            first: true
            last: !CalendarService.authenticated
            icon: CalendarService.authenticated ? "account_circle" : "no_accounts"
            iconColour: CalendarService.authenticated ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            label: CalendarService.authenticated ? Tr.tr("Connected") : Tr.tr("Not connected")
            subtext: CalendarService.authenticated
                ? (CalendarService.accountEmail || Tr.tr("Google account linked"))
                : Tr.tr("Sign in to sync your Google Calendar events")
            value: CalendarService.authenticated ? Tr.tr("Active") : ""
        }

        RowButton {
            visible: CalendarService.authenticated
            icon: "sync"
            text: Tr.tr("Sync now")
            subtext: CalendarService.statusMessage.length > 0
                ? CalendarService.statusMessage
                : (CalendarService.lastSyncTime.getTime() > 0
                    ? Tr.tr("Last synced: %1").arg(CalendarService.lastSyncTime.toLocaleTimeString())
                    : Tr.tr("Click to synchronize events now"))
            disabled: CalendarService.syncing
            onClicked: CalendarService.sync()
        }

        RowButton {
            visible: CalendarService.authenticated
            last: true
            icon: "logout"
            text: Tr.tr("Disconnect account")
            subtext: Tr.tr("Remove tokens and stop syncing")
            onClicked: CalendarService.logout()
        }

        // Credentials Setup (only when not authenticated)
        SectionHeader {
            visible: !CalendarService.authenticated
            text: Tr.tr("Credentials setup")
        }

        RowButton {
            visible: !CalendarService.authenticated
            first: true
            icon: "file_open"
            text: Tr.tr("Import client_secret.json")
            subtext: root.credentialsPath.length > 0 ? root.credentialsPath : Tr.tr("Select downloaded OAuth credentials file")
            onClicked: browseCredentialsDialog.open()

            FileDialog {
                id: browseCredentialsDialog

                title: Tr.tr("Select Google Client Secret JSON")
                filterLabel: Tr.tr("JSON files")
                filters: ["json"]
                onAccepted: path => {
                    root.credentialsPath = path;
                }
            }
        }

        TextFieldRow {
            visible: !CalendarService.authenticated
            label: Tr.tr("Client ID")
            subtext: Tr.tr("Google Cloud OAuth 2.0 Client ID")
            placeholderText: "xxxx.apps.googleusercontent.com"
            value: root.clientIdText
            onValueEdited: val => root.clientIdText = val
        }

        TextFieldRow {
            visible: !CalendarService.authenticated
            label: Tr.tr("Client Secret")
            subtext: Tr.tr("Google Cloud OAuth 2.0 Client Secret")
            placeholderText: Tr.tr("Enter client secret")
            value: root.clientSecretText
            onValueEdited: val => root.clientSecretText = val
        }

        RowButton {
            visible: !CalendarService.authenticated
            last: true
            icon: "login"
            trailingIcon: "open_in_browser"
            text: CalendarService.syncing ? Tr.tr("Signing in...") : Tr.tr("Sign in with Google")
            subtext: Tr.tr("Opens browser to authorize calendar access")
            disabled: CalendarService.syncing || (root.credentialsPath.length === 0 && (root.clientIdText.trim().length === 0 || root.clientSecretText.trim().length === 0))
            onClicked: {
                CalendarService.login(root.clientIdText.trim(), root.clientSecretText.trim(), root.credentialsPath);
            }
        }

        // Discovered Calendars
        SectionHeader {
            visible: CalendarService.authenticated && CalendarService.calendars.length > 0
            text: Tr.tr("Calendars")
        }

        Repeater {
            model: CalendarService.authenticated ? CalendarService.calendars : []

            delegate: ToggleRow {
                id: calToggle

                required property var modelData
                required property int index

                first: index === 0
                last: index === CalendarService.calendars.length - 1
                text: calToggle.modelData.summary || Tr.tr("Calendar")
                subtext: calToggle.modelData.primary ? Tr.tr("Primary calendar") : ""
                checked: Boolean(calToggle.modelData.enabled)
                onToggled: {
                    CalendarService.toggleCalendar(calToggle.modelData.id, checked);
                }
            }
        }

        // Sync & Polling Settings
        SectionHeader {
            visible: CalendarService.authenticated
            text: Tr.tr("Sync settings")
        }

        StepperRow {
            visible: CalendarService.authenticated
            first: true
            last: true
            label: Tr.tr("Sync interval")
            subtext: Tr.tr("How often events are refreshed (minutes)")
            value: Math.round(CalendarService.syncInterval / 60)
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => CalendarService.syncInterval = Math.round(v * 60)
        }
    }
}
