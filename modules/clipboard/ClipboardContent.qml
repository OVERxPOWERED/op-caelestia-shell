pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    required property ShellScreen screen
    signal closeRequested

    property var allItems: []
    property var filteredItems: []
    property bool loading: false
    property real openedAt: 0

    readonly property string monoFontFamily: "JetBrainsMono Nerd Font, JetBrains Mono NF, JetBrains Mono, monospace"

    function refresh() {
        if (!fetchProcess.running) {
            loading = true;
            fetchProcess.running = true;
        }
    }

    function applyFilter() {
        const query = searchInput.text.toLowerCase().trim();
        if (query === "") {
            filteredItems = allItems;
        } else {
            const res = [];
            for (let i = 0; i < allItems.length; i++) {
                const item = allItems[i];
                const titleMatch = (item.title || "").toLowerCase().includes(query);
                const detailsMatch = (item.details || "").toLowerCase().includes(query);
                if (titleMatch || detailsMatch) {
                    res.push(item);
                }
            }
            filteredItems = res;
        }
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    function copyItem(id) {
        actionProcess.command = ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "copy", id];
        actionProcess.running = true;
        if (ClipboardSettings.autoClearSearch) {
            searchInput.text = "";
        }
        root.closeRequested();
    }

    function deleteItem(id) {
        actionProcess.command = ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "delete", id];
        actionProcess.running = true;
        allItems = allItems.filter(it => it.id !== id);
        applyFilter();
    }

    Process {
        id: fetchProcess
        running: true
        command: ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "list", `${ClipboardSettings.maxHistory}`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    root.allItems = JSON.parse(text);
                    root.applyFilter();
                } catch (e) {
                    console.error("Clipboard JSON parse error:", e);
                }
            }
        }
    }

    Process {
        id: actionProcess
    }

    onVisibleChanged: {
        if (visible) {
            openedAt = Date.now();
            refresh();
            if (ClipboardSettings.autoFocusSearch) {
                searchInput.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        openedAt = Date.now();
        refresh();
        if (ClipboardSettings.autoFocusSearch) {
            searchInput.forceActiveFocus();
        }
    }

    // Modal Card Container: 850px width, 550px height (Fuzzel proportions)
    Elevation {
        id: cardElevation

        anchors.centerIn: parent
        width: 850
        height: 550
        radius: 10
        level: 3

        StyledRect {
            id: card

            anchors.fill: parent
            radius: parent.radius
            color: Colours.tPalette.m3surfaceContainer
            border.width: 2
            border.color: Colours.light ? Qt.alpha(Colours.palette.m3primary, 0.45) : Qt.alpha(Colours.palette.m3primary, 0.40)

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 8

                // -----------------------------------------------------------------
                // Top Search Row: Fuzzel prompt "> " + query + match counter "750/750"
                // -----------------------------------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignTop
                    spacing: 8

                    StyledText {
                        text: "> "
                        font.family: root.monoFontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Colours.palette.m3primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter

                        TextInput {
                            id: searchInput

                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: root.monoFontFamily
                            font.pixelSize: 15
                            color: Colours.palette.m3onSurface
                            selectionColor: Qt.alpha(Colours.palette.m3primary, 0.35)
                            selectedTextColor: Colours.palette.m3onSurface
                            selectByMouse: true
                            clip: true

                            onTextChanged: root.applyFilter()
                            
                            onAccepted: {
                                if (Date.now() - root.openedAt < 400) return;
                                list.copyCurrent();
                            }

                            Keys.onUpPressed: {
                                if (list.currentIndex > 0) {
                                    list.currentIndex--;
                                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                }
                            }

                            Keys.onDownPressed: {
                                if (list.currentIndex < list.count - 1) {
                                    list.currentIndex++;
                                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                }
                            }

                            Keys.onDeletePressed: {
                                if (list.currentIndex >= 0 && list.currentIndex < root.filteredItems.length) {
                                    root.deleteItem(root.filteredItems[list.currentIndex].id);
                                }
                            }

                            Keys.onEscapePressed: event => {
                                event.accepted = true;
                                if (Date.now() - root.openedAt < 400) return;
                                if (searchInput.text !== "") {
                                    searchInput.text = "";
                                } else {
                                    root.closeRequested();
                                }
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: Tr.tr("Type to search clipboard...")
                                color: Colours.palette.m3outline
                                font.family: root.monoFontFamily
                                font.pixelSize: 15
                                visible: !searchInput.text && !searchInput.inputMethodComposing
                            }
                        }
                    }

                    // Match counter (matching / total) e.g. 750/750
                    StyledText {
                        text: `${root.filteredItems.length}/${root.allItems.length}`
                        font.family: root.monoFontFamily
                        font.pixelSize: 15
                        color: Colours.palette.m3outline
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 4
                    }
                }

                // Hairline divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.alpha(Colours.palette.m3outlineVariant, 0.25)
                }

                // -----------------------------------------------------------------
                // Main List Area: Uniform 36px Rows, Instant 1:1 Fuzzel Scrolling
                // -----------------------------------------------------------------
                StyledListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2

                    boundsBehavior: Flickable.StopAtBounds
                    highlightRangeMode: ListView.NoHighlightRange
                    keyNavigationWraps: false

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: list
                    }

                    model: root.filteredItems

                    function copyCurrent(): void {
                        if (currentIndex >= 0 && currentIndex < root.filteredItems.length) {
                            const it = root.filteredItems[currentIndex];
                            root.copyItem(it.id);
                        }
                    }

                    highlightFollowsCurrentItem: false

                    delegate: Item {
                        id: itemDelegate

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: list.currentIndex === index
                        readonly property bool isHovered: itemMouse.containsMouse
                        readonly property bool isImage: modelData.type === "image"

                        width: list.width
                        height: (isImage && isSelected) ? 96 : 36

                        StyledRect {
                            anchors.fill: parent
                            radius: 6
                            color: itemDelegate.isSelected 
                                ? Qt.alpha(Colours.palette.m3primary, 0.22) 
                                : (itemDelegate.isHovered ? Qt.alpha(Colours.palette.m3onSurface, 0.05) : "transparent")
                            border.width: (itemDelegate.isImage && itemDelegate.isSelected) ? 1 : 0
                            border.color: Qt.alpha(Colours.palette.m3primary, 0.35)

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (itemDelegate.isImage && !itemDelegate.isSelected) {
                                        list.currentIndex = itemDelegate.index;
                                        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                    } else {
                                        root.copyItem(itemDelegate.modelData.id);
                                    }
                                }
                            }

                            // -------------------------------------------------------------
                            // CASE A: EXPANDED SELECTED IMAGE INSPECT PREVIEW (96px)
                            // -------------------------------------------------------------
                            RowLayout {
                                visible: itemDelegate.isImage && itemDelegate.isSelected
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 12

                                // Large Thumbnail Preview Box
                                StyledRect {
                                    Layout.preferredWidth: 80
                                    Layout.preferredHeight: 80
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 6
                                    color: Colours.palette.m3surfaceContainerHighest
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: itemDelegate.modelData.thumb ? `file://${itemDelegate.modelData.thumb}` : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        smooth: true
                                    }
                                }

                                // Metadata Column
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 5

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: itemDelegate.modelData.title
                                        font.family: root.monoFontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: Colours.palette.m3primary
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: itemDelegate.modelData.details
                                        font.family: root.monoFontFamily
                                        font.pixelSize: 13
                                        color: Colours.palette.m3onSurfaceVariant
                                        elide: Text.ElideRight
                                    }
                                }

                                // Quick Actions: Copy and Delete
                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    IconButton {
                                        icon: "content_copy"
                                        type: IconButton.Text
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        onClicked: root.copyItem(itemDelegate.modelData.id)
                                    }

                                    IconButton {
                                        icon: "delete"
                                        type: IconButton.Text
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        onClicked: root.deleteItem(itemDelegate.modelData.id)
                                    }
                                }
                            }

                            // -------------------------------------------------------------
                            // CASE B: COMPACT ROW (36px - Unselected Image or Any Text)
                            // -------------------------------------------------------------
                            RowLayout {
                                visible: !(itemDelegate.isImage && itemDelegate.isSelected)
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                // Image micro-thumbnail or type icon
                                Item {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignVCenter

                                    // Crisp 26x26 thumbnail for images
                                    StyledRect {
                                        visible: itemDelegate.isImage
                                        anchors.fill: parent
                                        radius: 3
                                        color: Colours.palette.m3surfaceContainerHighest
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: itemDelegate.modelData.thumb ? `file://${itemDelegate.modelData.thumb}` : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }
                                    }

                                    // Micro icon for text
                                    MaterialIcon {
                                        visible: !itemDelegate.isImage
                                        anchors.centerIn: parent
                                        text: itemDelegate.modelData.type === "url" ? "link" : (itemDelegate.modelData.type === "code" ? "terminal" : "notes")
                                        color: itemDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.builders.small.scale(0.75).build()
                                    }
                                }

                                // Main Text Content in JetBrains Mono
                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: itemDelegate.isImage ? `Image (${itemDelegate.modelData.details || itemDelegate.modelData.title})` : itemDelegate.modelData.title
                                    font.family: root.monoFontFamily
                                    font.pixelSize: 14
                                    color: itemDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Quick actions visible on hover or selection
                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    visible: itemDelegate.isSelected || itemMouse.containsMouse

                                    IconButton {
                                        icon: "content_copy"
                                        type: IconButton.Text
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        onClicked: root.copyItem(itemDelegate.modelData.id)
                                    }

                                    IconButton {
                                        icon: "delete"
                                        type: IconButton.Text
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        onClicked: root.deleteItem(itemDelegate.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
