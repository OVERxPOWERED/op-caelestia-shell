pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

// Settings search results, shown in place of the page area while searching.
Item {
    id: root

    required property NexusState nState

    readonly property list<string> pageLabels: PageRegistry.pages.map(p => p.label)
    readonly property var results: nState.searchOpen ? SearchEngine.search(nState.searchText, pageLabels) : []
    property int currentIndex

    function open(idx: int): void {
        const e = results[idx]?.entry;
        if (e)
            nState.openSearchResult(e.page, e.sub, e.label, e.kind === "row");
    }

    function breadcrumb(e: var): string {
        const parts = [pageLabels[e.page]];
        if (e.sub > 0 && e.kind === "row")
            parts.push(e.subTitle);
        if (e.section && e.kind === "row")
            parts.push(e.section);
        return parts.join("  ›  ");
    }

    onResultsChanged: {
        currentIndex = 0;
        list.positionViewAtBeginning();
    }

    Connections {
        function onSearchMove(delta: int): void {
            if (root.results.length === 0)
                return;
            root.currentIndex = Math.max(0, Math.min(root.results.length - 1, root.currentIndex + delta));
            list.positionViewAtIndex(root.currentIndex, ListView.Contain);
        }

        function onSearchActivate(): void {
            root.open(root.currentIndex);
        }

        target: root.nState
    }

    StyledText {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        text: root.results.length > 0 ? Tr.tr("Search results") : Tr.tr("No results")
        font: Tokens.font.title.large
        elide: Text.ElideRight
    }

    VerticalFadeListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Tokens.spacing.large

        topMargin: Tokens.padding.small
        bottomMargin: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall
        clip: true
        model: root.results

        delegate: StyledRect {
            id: item

            required property var modelData
            required property int index

            readonly property var entry: modelData.entry
            readonly property bool selected: index === root.currentIndex

            width: list.width
            implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
            radius: Tokens.rounding.large
            color: selected ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

            StateLayer {
                anchors.fill: parent
                radius: parent.radius
                onClicked: {
                    root.currentIndex = item.index;
                    root.open(item.index);
                }
            }

            RowLayout {
                id: layout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    implicitWidth: iconText.implicitHeight + Tokens.padding.medium
                    implicitHeight: implicitWidth

                    radius: Tokens.rounding.full
                    color: item.selected ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: iconText

                        anchors.centerIn: parent
                        text: PageRegistry.pages[item.entry.page]?.icon ?? "settings"
                        color: item.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                        grade: 25
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: item.entry.label
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.breadcrumb(item.entry)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3outline
                    visible: item.selected
                }
            }
        }
    }

    // Shown when the query matches nothing
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.results.length === 0
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "search_off"
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Nothing matches “%1”").arg(root.nState.searchText)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }
    }
}
