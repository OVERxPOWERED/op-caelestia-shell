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

    readonly property alias cardOpacity: card.opacity

    property string initialTab: "clipboard"
    property string currentTab: initialTab

    property var allItems: []
    property var filteredItems: []
    property var filteredEmojis: []
    property bool loading: false
    property real openedAt: 0

    readonly property string monoFontFamily: "JetBrainsMono Nerd Font, JetBrains Mono NF, JetBrains Mono, monospace"

    onInitialTabChanged: {
        currentTab = initialTab;
    }

    onCurrentTabChanged: {
        searchInput.text = "";
        if (currentTab === "clipboard") {
            refreshClipboard();
        } else {
            refreshEmojis();
        }
        searchInput.forceActiveFocus();
    }

    function requestClose(): void {
        if (exitAnim.running) return;
        enterAnim.stop();
        exitAnim.restart();
    }

    function refreshClipboard() {
        if (!fetchProcess.running) {
            loading = true;
            fetchProcess.running = true;
        }
    }

    function refreshEmojis() {
        if (!emojiProcess.running) {
            emojiProcess.command = ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "emojis", searchInput.text.trim(), "2000"];
            emojiProcess.running = true;
        }
    }

    function applyFilter() {
        if (currentTab === "clipboard") {
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
        } else {
            emojiSearchDebounce.restart();
        }
    }

    function copyItem(id) {
        Quickshell.execDetached(["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "copy", id]);
        if (ClipboardSettings.autoClearSearch) {
            searchInput.text = "";
        }
        root.requestClose();
    }

    function copyEmoji(glyph) {
        Quickshell.execDetached(["wl-copy", glyph]);
        if (ClipboardSettings.autoClearSearch) {
            searchInput.text = "";
        }
        root.requestClose();
    }

    function deleteItem(id) {
        Quickshell.execDetached(["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "delete", id]);
        allItems = allItems.filter(it => it.id !== id);
        applyFilter();
    }

    // Process for fetching clipboard items
    Process {
        id: fetchProcess
        running: true
        command: ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "list", `${ClipboardSettings.maxHistory || 1000}`]
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

    // Process for fetching emojis
    Process {
        id: emojiProcess
        running: false
        command: ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "emojis", "", "2000"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.filteredEmojis = JSON.parse(text);
                    emojiList.currentIndex = 0;
                    emojiList.positionViewAtBeginning();
                } catch (e) {
                    console.error("Emoji JSON parse error:", e);
                }
            }
        }
    }

    Timer {
        id: emojiSearchDebounce
        interval: 60
        repeat: false
        onTriggered: {
            if (root.currentTab === "emojis") {
                emojiProcess.command = ["python3", `${Quickshell.shellDir}/modules/clipboard/services/clipboard-helper.py`, "emojis", searchInput.text.trim(), "2000"];
                emojiProcess.running = true;
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            openedAt = Date.now();
            currentTab = initialTab;
            if (currentTab === "clipboard") {
                refreshClipboard();
            } else {
                refreshEmojis();
            }
            if (ClipboardSettings.autoFocusSearch) {
                searchInput.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        openedAt = Date.now();
        currentTab = initialTab;
        if (currentTab === "clipboard") {
            refreshClipboard();
        } else {
            refreshEmojis();
        }
        if (ClipboardSettings.autoFocusSearch) {
            searchInput.forceActiveFocus();
        }
    }

    // Modal Card Container: 850px width, 560px height with true frosted acrylic blur
    StyledRect {
        id: card

        anchors.centerIn: parent
        width: 850
        height: 560
        radius: Tokens.rounding.extraLarge
        color: Colours.transparency.enabled 
            ? Qt.alpha(Colours.palette.m3surface, 0.72) 
            : Colours.palette.m3surface
        border.width: 1
        border.color: Colours.light ? Qt.alpha(Colours.palette.m3outline, 0.25) : Qt.alpha(Colours.palette.m3outline, 0.20)

        transformOrigin: Item.Center
        scale: 0.92
        opacity: 0.0

        ParallelAnimation {
            id: enterAnim
            running: true

            Anim {
                target: card
                property: "scale"
                from: 0.92
                to: 1.0
            }

            Anim {
                target: card
                property: "opacity"
                from: 0.0
                to: 1.0
                type: Anim.DefaultEffects
            }
        }

        SequentialAnimation {
            id: exitAnim
            running: false

            ParallelAnimation {
                Anim {
                    target: card
                    property: "scale"
                    from: card.scale
                    to: 0.92
                    type: Anim.FastSpatial
                }

                Anim {
                    target: card
                    property: "opacity"
                    from: card.opacity
                    to: 0.0
                    type: Anim.FastEffects
                }
            }

            ScriptAction {
                script: root.closeRequested()
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 10

            // -----------------------------------------------------------------
            // Top Header Row: Prompt "> " + Query Input + Flat Tabs + Counter
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignTop
                spacing: 10

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
                    Layout.preferredHeight: 30
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
                            if (root.currentTab === "clipboard") {
                                list.copyCurrent();
                            } else {
                                emojiList.copyCurrent();
                            }
                        }

                        Keys.onUpPressed: {
                            if (root.currentTab === "clipboard") {
                                list.decrementCurrentIndex();
                            } else {
                                emojiList.decrementCurrentIndex();
                            }
                        }

                        Keys.onDownPressed: {
                            if (root.currentTab === "clipboard") {
                                list.incrementCurrentIndex();
                            } else {
                                emojiList.incrementCurrentIndex();
                            }
                        }

                        Keys.onDeletePressed: {
                            if (root.currentTab === "clipboard") {
                                if (list.currentIndex >= 0 && list.currentIndex < root.filteredItems.length) {
                                    root.deleteItem(root.filteredItems[list.currentIndex].id);
                                }
                            }
                        }

                        Keys.onTabPressed: event => {
                            event.accepted = true;
                            root.currentTab = (root.currentTab === "clipboard" ? "emojis" : "clipboard");
                        }

                        Keys.onEscapePressed: event => {
                            event.accepted = true;
                            if (Date.now() - root.openedAt < 400) return;
                            if (searchInput.text !== "") {
                                searchInput.text = "";
                            } else {
                                root.requestClose();
                            }
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentTab === "clipboard" ? Tr.tr("Type to search clipboard...") : Tr.tr("Type to search emojis & symbols...")
                            color: Colours.palette.m3outline
                            font.family: root.monoFontFamily
                            font.pixelSize: 15
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }
                    }
                }

                // Sleek, Flat Tab Indicator & Counter (Zero Puffiness)
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12

                    // History Tab Label
                    MouseArea {
                        id: tabClipMouse
                        implicitWidth: tabHistoryText.implicitWidth
                        implicitHeight: 24
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentTab = "clipboard";
                        }

                        StyledText {
                            id: tabHistoryText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "History"
                            font.family: root.monoFontFamily
                            font.pixelSize: 13
                            font.bold: root.currentTab === "clipboard"
                            color: root.currentTab === "clipboard" 
                                ? Colours.palette.m3primary 
                                : (tabClipMouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
                        }
                    }

                    // Subtle Divider Dot
                    StyledText {
                        text: "•"
                        font.family: root.monoFontFamily
                        font.pixelSize: 11
                        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.45)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Emojis Tab Label
                    MouseArea {
                        id: tabEmojiMouse
                        implicitWidth: tabEmojiText.implicitWidth
                        implicitHeight: 24
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentTab = "emojis";
                        }

                        StyledText {
                            id: tabEmojiText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Emojis"
                            font.family: root.monoFontFamily
                            font.pixelSize: 13
                            font.bold: root.currentTab === "emojis"
                            color: root.currentTab === "emojis" 
                                ? Colours.palette.m3primary 
                                : (tabEmojiMouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
                        }
                    }

                    // Hairline Separator before counter
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 12
                        Layout.alignment: Qt.AlignVCenter
                        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.3)
                    }

                    // Match counter (matching / total) e.g. 80/80 or 47 glyphs
                    StyledText {
                        text: root.currentTab === "clipboard" 
                            ? (root.allItems.length > 0 ? `${root.filteredItems.length}/${root.allItems.length}` : "")
                            : `${root.filteredEmojis.length} glyphs`
                        font.family: root.monoFontFamily
                        font.pixelSize: 13
                        color: Colours.palette.m3outline
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Hairline divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.25)
            }

            // -----------------------------------------------------------------
            // MAIN CONTENT: Tab 1 (Clipboard History) OR Tab 2 (Emojis Picker)
            // -----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // =============================================================
                // TAB 1: CLIPBOARD HISTORY LIST VIEW
                // =============================================================
                StyledListView {
                    id: list

                    anchors.fill: parent
                    visible: root.currentTab === "clipboard"
                    clip: true
                    spacing: 2

                    boundsBehavior: Flickable.StopAtBounds
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height
                    highlightRangeMode: ListView.ApplyRange
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
                    highlight: StyledRect {
                        id: listHighlight
                        radius: 6
                        color: Qt.alpha(Colours.palette.m3primary, 0.20)
                        border.width: 1
                        border.color: Qt.alpha(Colours.palette.m3primary, 0.35)

                        y: list.currentItem?.y ?? 0
                        width: list.width
                        height: list.currentItem?.height ?? 36
                        visible: list.currentItem !== null && list.count > 0
                        z: 0

                        Behavior on y {
                            Anim {}
                        }
                        Behavior on height {
                            Anim {}
                        }
                    }

                    delegate: Item {
                        id: itemDelegate

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: list.currentIndex === index
                        readonly property bool isHovered: itemHover.hovered
                        readonly property bool isImage: modelData.type === "image"

                        width: list.width
                        height: (isImage && isSelected) ? 96 : 36

                        HoverHandler {
                            id: itemHover
                        }

                        StyledRect {
                            anchors.fill: parent
                            radius: 6
                            color: (itemDelegate.isHovered && !itemDelegate.isSelected) 
                                ? Qt.alpha(Colours.palette.m3onSurface, 0.06) 
                                : "transparent"
                            border.width: 0

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (itemDelegate.isImage && !itemDelegate.isSelected) {
                                        list.currentIndex = itemDelegate.index;
                                    } else {
                                        root.copyItem(itemDelegate.modelData.id);
                                    }
                                }
                            }

                            // Case A: Expanded Selected Image Inspect Preview (96px)
                            RowLayout {
                                visible: itemDelegate.isImage && itemDelegate.isSelected
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 12

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
                                        color: itemDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 150 } }
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

                            // Case B: Compact Row (36px - Unselected Image or Any Text)
                            RowLayout {
                                visible: !(itemDelegate.isImage && itemDelegate.isSelected)
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                Item {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignVCenter

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

                                    MaterialIcon {
                                        visible: !itemDelegate.isImage
                                        anchors.centerIn: parent
                                        text: itemDelegate.modelData.type === "url" ? "link" : (itemDelegate.modelData.type === "code" ? "terminal" : "notes")
                                        color: itemDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.builders.small.scale(0.75).build()
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: itemDelegate.isImage ? `Image (${itemDelegate.modelData.details || itemDelegate.modelData.title})` : itemDelegate.modelData.title
                                    font.family: root.monoFontFamily
                                    font.pixelSize: 14
                                    color: itemDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    visible: itemDelegate.isSelected || itemDelegate.isHovered

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

                // =============================================================
                // TAB 2: EMOJIS & SYMBOLS PICKER LIST VIEW
                // =============================================================
                StyledListView {
                    id: emojiList

                    anchors.fill: parent
                    visible: root.currentTab === "emojis"
                    clip: true
                    spacing: 2

                    boundsBehavior: Flickable.StopAtBounds
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height
                    highlightRangeMode: ListView.ApplyRange
                    keyNavigationWraps: false

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: emojiList
                    }

                    model: root.filteredEmojis

                    function copyCurrent(): void {
                        if (currentIndex >= 0 && currentIndex < root.filteredEmojis.length) {
                            const e = root.filteredEmojis[currentIndex];
                            root.copyEmoji(e.char);
                        }
                    }

                    highlightFollowsCurrentItem: false
                    highlight: StyledRect {
                        id: emojiHighlight
                        radius: 6
                        color: Qt.alpha(Colours.palette.m3primary, 0.20)
                        border.width: 1
                        border.color: Qt.alpha(Colours.palette.m3primary, 0.35)

                        y: emojiList.currentItem?.y ?? 0
                        width: emojiList.width
                        height: emojiList.currentItem?.height ?? 42
                        visible: emojiList.currentItem !== null && emojiList.count > 0
                        z: 0

                        Behavior on y {
                            Anim {}
                        }
                    }

                    delegate: Item {
                        id: emojiDelegate

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: emojiList.currentIndex === index
                        readonly property bool isHovered: emojiHover.hovered

                        width: emojiList.width
                        height: 42

                        HoverHandler {
                            id: emojiHover
                        }

                        StyledRect {
                            anchors.fill: parent
                            radius: 6
                            color: (emojiDelegate.isHovered && !emojiDelegate.isSelected) 
                                ? Qt.alpha(Colours.palette.m3onSurface, 0.06) 
                                : "transparent"
                            border.width: 0

                            MouseArea {
                                id: emojiMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.copyEmoji(emojiDelegate.modelData.char);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 12

                                // Emoji / Glyph Display Box
                                Item {
                                    Layout.preferredWidth: Math.max(34, glyphText.implicitWidth + 8)
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: glyphText
                                        anchors.centerIn: parent
                                        text: emojiDelegate.modelData.char || ""
                                        font.pixelSize: 20
                                        font.family: root.monoFontFamily
                                        color: Colours.palette.m3onSurface
                                    }
                                }

                                // Description Column
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: emojiDelegate.modelData.title || emojiDelegate.modelData.char
                                        font.family: root.monoFontFamily
                                        font.pixelSize: 13
                                        font.bold: emojiDelegate.isSelected
                                        color: emojiDelegate.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: emojiDelegate.modelData.tags || ""
                                        font.family: root.monoFontFamily
                                        font.pixelSize: 11
                                        color: Colours.palette.m3outline
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        visible: text.length > 0
                                    }
                                }

                                // Quick Copy Action Icon
                                IconButton {
                                    visible: emojiDelegate.isSelected || emojiDelegate.isHovered
                                    icon: "content_copy"
                                    type: IconButton.Text
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: root.copyEmoji(emojiDelegate.modelData.char)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
