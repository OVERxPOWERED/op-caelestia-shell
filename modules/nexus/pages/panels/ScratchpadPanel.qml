pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Scratchpad & Notes")
    isSubPage: true

    property string newTagInput: ""

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Section: Storage & Directory
        SectionHeader {
            first: true
            text: qsTr("Storage & Paths")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: storageCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: storageCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "folder"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: qsTr("Notes Directory")
                        font: Tokens.font.body.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: QuickNoteState.notesDir.replace(Paths.home, "~")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideMiddle
                }

                RowLayout {
                    Layout.topMargin: Tokens.spacing.extraSmall
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        type: ButtonBase.Tonal
                        icon: "folder_open"
                        text: qsTr("Open Folder")
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", QuickNoteState.notesDir]);
                        }
                    }

                    IconTextButton {
                        type: ButtonBase.Outlined
                        icon: "refresh"
                        text: qsTr("Rescan Notes")
                        onClicked: {
                            QuickNoteState.refreshFiles();
                        }
                    }
                }
            }
        }

        // Section: Custom Tags
        SectionHeader {
            text: qsTr("Custom Tags")
        }

        // Add New Tag Input Box
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: QuickNoteState.customTags.length === 0
            implicitHeight: addTagRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: addTagRow
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "new_label"
                    color: Colours.palette.m3primary
                }

                StyledTextField {
                    id: tagInputField
                    Layout.fillWidth: true
                    placeholderText: qsTr("New tag name (e.g. project, reading)...")
                    text: root.newTagInput
                    onTextChanged: root.newTagInput = text
                    onAccepted: {
                        if (root.newTagInput.trim()) {
                            QuickNoteState.addCustomTag(root.newTagInput);
                            root.newTagInput = "";
                        }
                    }
                }

                IconTextButton {
                    type: ButtonBase.Filled
                    icon: "add"
                    text: qsTr("Add Tag")
                    onClicked: {
                        if (root.newTagInput.trim()) {
                            QuickNoteState.addCustomTag(root.newTagInput);
                            root.newTagInput = "";
                        }
                    }
                }
            }
        }

        // List of Custom Tags
        Repeater {
            model: QuickNoteState.customTags

            ConnectedRect {
                id: tagRow
                required property string modelData
                required property int index

                readonly property int noteCount: {
                    let count = 0;
                    for (let i = 0; i < QuickNoteState.availableFiles.length; i++) {
                        const tags = QuickNoteState.getTagsForFile(QuickNoteState.availableFiles[i]);
                        if (tags.includes(modelData)) count++;
                    }
                    return count;
                }

                Layout.fillWidth: true
                first: false
                last: index === QuickNoteState.customTags.length - 1
                implicitHeight: tagContentRow.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: tagContentRow
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    // Tag Badge
                    StyledRect {
                        implicitWidth: badgeLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StyledText {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: `#${tagRow.modelData}`
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("%1 notes tagged").arg(tagRow.noteCount)
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        onClicked: {
                            QuickNoteState.removeCustomTag(tagRow.modelData);
                        }
                    }
                }
            }
        }

        // Section: Shortcuts
        SectionHeader {
            text: qsTr("Quick Access")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: accessCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: accessCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "keyboard"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: qsTr("Scratchpad IPC & Hotkeys")
                        font: Tokens.font.body.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Run `caelestia ipc quicknote toggle` or bind it in Hyprland to pop up your scratchpad with tags from anywhere.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
