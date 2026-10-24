pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.images
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    signal closeRequested

    property bool showFilePicker: false
    property bool showTagAssignMenu: false
    property bool showNewNotePrompt: false
    property string newNoteName: ""
    property string saveStatusText: Tr.tr("Saved ✓")

    focus: true

    Keys.onEscapePressed: event => {
        event.accepted = true;
        root.saveFile();
        root.closeRequested();
    }

    function saveFile(): void {
        if (noteFile.path && textEditor.text !== undefined) {
            noteFile.setText(textEditor.text);
            root.saveStatusText = Tr.tr("Saved ✓");
        }
    }

    function attachContext(): void {
        const title = QuickNoteState.activeAppTitle || "Active App";
        const app = QuickNoteState.activeAppClass || "Context";
        const time = QuickNoteState.activeTimestamp || Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm");
        const contextStr = `\n--- Context: ${app} (${title}) [${time}] ---\n`;
        textEditor.insert(textEditor.cursorPosition, contextStr);
        saveDebounceTimer.restart();
    }

    function insertTag(tagName: string): void {
        const tagStr = `[${tagName}] `;
        const pos = textEditor.cursorPosition >= 0 ? textEditor.cursorPosition : textEditor.text.length;
        textEditor.insert(pos, tagStr);
        textEditor.cursorPosition = pos + tagStr.length;
        textEditor.forceActiveFocus();
        root.saveStatusText = Tr.tr("Editing...");
        saveDebounceTimer.restart();
    }

    Timer {
        id: saveDebounceTimer

        interval: 600
        repeat: false
        onTriggered: root.saveFile()
    }

    FileView {
        id: noteFile

        path: QuickNoteState.currentFilePath
        onLoaded: {
            textEditor.text = text();
            root.saveStatusText = Tr.tr("Saved ✓");
        }
        onLoadFailed: {
            textEditor.text = "";
            root.saveStatusText = Tr.tr("New Note");
        }
    }

    // Transparent backdrop click-catcher (completely invisible: rest of desktop stays unblurred)
    MouseArea {
        id: backdropCatcher
        anchors.fill: parent
        onClicked: {
            root.saveFile();
            root.closeRequested();
        }
    }

    // Centered Note Card
    Elevation {
        id: card

        anchors.centerIn: parent
        width: Math.min(root.screen.width * 0.72, 780)
        height: Math.min(root.screen.height * 0.75, 540)
        radius: Tokens.rounding.extraLargeIncreased
        level: 4

        MouseArea {
            anchors.fill: parent
            onClicked: parent.focus = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3surfaceContainer, Colours.transparency.base) : Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3outlineVariant, 0.45) : Colours.palette.m3outlineVariant

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                // Header Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "sticky_note_2"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }

                    // File Switcher Pill Button
                    IconTextButton {
                        id: filePill

                        type: ButtonBase.Tonal
                        icon: "description"
                        text: QuickNoteState.currentFileName
                        onClicked: root.showFilePicker = !root.showFilePicker
                    }

                    // Context Badge / Attachment Chip
                    IconTextButton {
                        id: contextChip

                        visible: QuickNoteState.activeAppTitle.length > 0 && QuickNoteState.activeAppTitle !== "Desktop"
                        type: ButtonBase.Tonal
                        icon: QuickNoteState.activeIcon ? "" : "link"
                        text: Tr.tr("+ Context: %1").arg(QuickNoteState.activeAppClass || "Window")
                        onClicked: root.attachContext()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Save Status Label
                    StyledText {
                        text: root.saveStatusText
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    // Open in Terminal Editor (nano in foot)
                    IconButton {
                        icon: "terminal"
                        type: IconButton.Tonal
                        onClicked: {
                            root.saveFile();
                            QuickNoteState.openInEditor(QuickNoteState.currentFileName);
                            root.closeRequested();
                        }
                    }

                    // Close Button
                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: {
                            root.saveFile();
                            root.closeRequested();
                        }
                    }
                }

                // Tag Filter & Management Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: "label"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    // "All" Chip
                    StyledRect {
                        implicitWidth: allChipText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 24
                        radius: Tokens.rounding.full
                        color: QuickNoteState.activeTagFilter === "all" ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 0)
                        border.width: 1
                        border.color: QuickNoteState.activeTagFilter === "all" ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        StyledText {
                            id: allChipText
                            anchors.centerIn: parent
                            text: qsTr("All")
                            font.pixelSize: 11
                            font.weight: QuickNoteState.activeTagFilter === "all" ? Font.Bold : Font.Normal
                            color: QuickNoteState.activeTagFilter === "all" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            onClicked: QuickNoteState.activeTagFilter = "all"
                        }
                    }

                    // Custom Tags Repeater
                    Repeater {
                        model: QuickNoteState.customTags

                        StyledRect {
                            id: tagChip
                            required property string modelData
                            required property int index

                            readonly property bool isSelected: QuickNoteState.activeTagFilter === modelData
                            readonly property bool isAssignedToCurrent: (QuickNoteState.fileTags[QuickNoteState.currentFileName] || []).includes(modelData)

                            implicitWidth: tagChipLayout.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: 24
                            radius: Tokens.rounding.full
                            color: isSelected
                                ? Colours.palette.m3primaryContainer
                                : (isAssignedToCurrent ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 0))
                            border.width: 1
                            border.color: isSelected
                                ? Colours.palette.m3primary
                                : (isAssignedToCurrent ? Colours.palette.m3secondary : Colours.palette.m3outlineVariant)

                            Row {
                                id: tagChipLayout
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    text: "bookmark"
                                    fontStyle: Tokens.font.icon.small
                                    color: tagChip.isAssignedToCurrent ? Colours.palette.m3primary : Colours.palette.m3outline
                                    visible: tagChip.isAssignedToCurrent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: `#${tagChip.modelData}`
                                    font.pixelSize: 11
                                    font.weight: tagChip.isSelected || tagChip.isAssignedToCurrent ? Font.Bold : Font.Normal
                                    color: tagChip.isSelected
                                        ? Colours.palette.m3onPrimaryContainer
                                        : (tagChip.isAssignedToCurrent ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StateLayer {
                                anchors.fill: parent
                                radius: Tokens.rounding.full
                                onClicked: {
                                    root.insertTag(tagChip.modelData);
                                }
                                onPressAndHold: {
                                    if (QuickNoteState.activeTagFilter === tagChip.modelData) {
                                        QuickNoteState.activeTagFilter = "all";
                                    } else {
                                        QuickNoteState.activeTagFilter = tagChip.modelData;
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Tag Current Note Button
                    IconTextButton {
                        type: ButtonBase.Text
                        icon: "label_important"
                        text: qsTr("Tag Note")
                        onClicked: root.showTagAssignMenu = !root.showTagAssignMenu
                    }

                    // New Note Button
                    IconButton {
                        icon: "note_add"
                        type: IconButton.Tonal
                        implicitWidth: 26
                        implicitHeight: 26
                        onClicked: root.showNewNotePrompt = !root.showNewNotePrompt
                    }
                }

                // Tag Assignment Dropdown
                StyledRect {
                    id: tagAssignPanel
                    visible: root.showTagAssignMenu
                    Layout.fillWidth: true
                    implicitHeight: assignCol.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    ColumnLayout {
                        id: assignCol
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Toggle tags for '%1':").arg(QuickNoteState.currentFileName)
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            Repeater {
                                model: QuickNoteState.customTags

                                StyledRect {
                                    id: assignChip
                                    required property string modelData
                                    readonly property bool isAssigned: (QuickNoteState.fileTags[QuickNoteState.currentFileName] || []).includes(modelData)

                                    implicitWidth: assignChipText.implicitWidth + 24
                                    implicitHeight: 26
                                    radius: Tokens.rounding.full
                                    color: isAssigned ? Colours.palette.m3primaryContainer : "transparent"
                                    border.width: 1
                                    border.color: isAssigned ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        MaterialIcon {
                                            text: assignChip.isAssigned ? "check_box" : "check_box_outline_blank"
                                            fontStyle: Tokens.font.icon.small
                                            color: assignChip.isAssigned ? Colours.palette.m3primary : Colours.palette.m3outline
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            id: assignChipText
                                            text: `#${assignChip.modelData}`
                                            font.pixelSize: 11
                                            color: assignChip.isAssigned ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    StateLayer {
                                        anchors.fill: parent
                                        radius: Tokens.rounding.full
                                        onClicked: {
                                            QuickNoteState.toggleTagForCurrentFile(assignChip.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // New Note Prompt
                StyledRect {
                    id: newNotePanel
                    visible: root.showNewNotePrompt
                    Layout.fillWidth: true
                    implicitHeight: newNoteRow.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    RowLayout {
                        id: newNoteRow
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            id: newNoteField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Enter new note name (e.g. Ideas.md)...")
                            text: root.newNoteName
                            onTextChanged: root.newNoteName = text
                            onAccepted: {
                                if (root.newNoteName.trim()) {
                                    QuickNoteState.createNewNote(root.newNoteName, QuickNoteState.activeTagFilter);
                                    root.newNoteName = "";
                                    root.showNewNotePrompt = false;
                                }
                            }
                        }

                        IconTextButton {
                            type: ButtonBase.Filled
                            icon: "add"
                            text: qsTr("Create")
                            onClicked: {
                                if (root.newNoteName.trim()) {
                                    QuickNoteState.createNewNote(root.newNoteName, QuickNoteState.activeTagFilter);
                                    root.newNoteName = "";
                                    root.showNewNotePrompt = false;
                                }
                            }
                        }
                    }
                }

                // File Picker Dropdown List
                StyledRect {
                    id: filePickerPanel

                    visible: root.showFilePicker
                    Layout.fillWidth: true
                    implicitHeight: Math.min(200, Math.max(40, QuickNoteState.getFilteredFiles().length * 36 + Tokens.padding.small * 2))
                    radius: Tokens.rounding.medium
                    color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.85) : Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Colours.tPalette.m3outlineVariant

                    VerticalFadeListView {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        model: QuickNoteState.getFilteredFiles()
                        spacing: 2

                        delegate: StyledRect {
                            id: fileItem

                            required property string modelData
                            readonly property bool isCur: modelData === QuickNoteState.currentFileName
                            readonly property var itemTags: QuickNoteState.getTagsForFile(modelData)

                            anchors.left: parent?.left
                            anchors.right: parent?.right
                            implicitHeight: 32
                            radius: Tokens.rounding.small
                            color: isCur ? Qt.alpha(Colours.palette.m3primaryContainer, 0.7) : (itemMa.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

                            StateLayer {
                                id: itemMa
                                anchors.fill: parent
                                radius: parent.radius
                                onClicked: {
                                    root.saveFile();
                                    QuickNoteState.currentFileName = fileItem.modelData;
                                    root.showFilePicker = false;
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.small
                                anchors.rightMargin: Tokens.padding.small
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    text: "draft"
                                    color: fileItem.isCur ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: fileItem.modelData
                                    font: Tokens.font.body.small
                                    color: fileItem.isCur ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                }

                                Repeater {
                                    model: fileItem.itemTags

                                    StyledRect {
                                        required property string modelData
                                        implicitWidth: fileTagText.implicitWidth + 8
                                        implicitHeight: 18
                                        radius: Tokens.rounding.full
                                        color: Colours.palette.m3secondaryContainer

                                        StyledText {
                                            id: fileTagText
                                            anchors.centerIn: parent
                                            text: `#${modelData}`
                                            font.pixelSize: 9
                                            color: Colours.palette.m3onSecondaryContainer
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Editor Box
                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Tokens.rounding.large
                    color: "transparent"
                    border.width: 1
                    border.color: Colours.transparency.enabled ? Qt.alpha(Colours.palette.m3outline, 0.2) : Colours.tPalette.m3outlineVariant

                    Flickable {
                        id: flick

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        contentWidth: width
                        contentHeight: textEditor.paintedHeight + Tokens.padding.large
                        clip: true

                        // Scroll just enough to keep the text cursor in view, with a line of
                        // context above or below, so the note can be used from the keyboard alone
                        function ensureCursorVisible(): void {
                            const r = textEditor.cursorRectangle;
                            const margin = r.height;
                            if (r.y - margin < contentY)
                                contentY = Math.max(0, r.y - margin);
                            else if (r.y + r.height + margin > contentY + height)
                                contentY = Math.min(Math.max(0, contentHeight - height), r.y + r.height + margin - height);
                        }

                        TextEdit {
                            id: textEditor

                            width: flick.width
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            color: Colours.palette.m3onSurface
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary
                            font: Tokens.font.body.medium
                            cursorVisible: true

                            onCursorRectangleChanged: flick.ensureCursorVisible()

                            onTextChanged: {
                                root.saveStatusText = Tr.tr("Editing...");
                                saveDebounceTimer.restart();
                            }

                            Component.onCompleted: {
                                textEditor.forceActiveFocus();
                            }
                        }
                    }
                }

                // Footer Info Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: QuickNoteState.currentFilePath.replace(Paths.home, "~")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                        elide: Text.ElideLeft
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Tr.tr("%1 characters").arg(textEditor.text.length)
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }
                }
            }
        }
    }
}
