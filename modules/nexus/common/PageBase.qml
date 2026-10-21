pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    readonly property int cappedWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable

    default property Item contentChild

    // Scrolls to the row labelled `label` and flashes it; false if it isn't there (yet)
    function highlightRow(label: string): bool {
        const hit = findLabel(contentChild, label);
        if (!hit)
            return false;

        // The row is the child of the layout that holds the settings list
        let row = hit;
        while (row.parent && row.parent !== flickable.contentItem && !String(row.parent).startsWith("QQuickColumnLayout"))
            row = row.parent;

        const pos = row.mapToItem(flickable.contentItem, 0, 0);
        const maxY = Math.max(-flickable.topMargin, flickable.contentHeight - flickable.height + flickable.bottomMargin);
        flickable.contentY = Math.max(-flickable.topMargin, Math.min(maxY, pos.y - flickable.height / 3));

        const view = row.mapToItem(flickable, 0, 0);
        flash.x = view.x;
        flash.y = view.y;
        flash.width = row.width;
        flash.height = row.height;
        flashAnim.restart();
        return true;
    }

    function findLabel(item: Item, label: string): Item {
        if (!item || !item.visible)
            return null;
        if (item.text === label && item.height > 0)
            return item;
        for (const child of item.children) {
            const hit = findLabel(child, label);
            if (hit)
                return hit;
        }
        return null;
    }

    spacing: Tokens.spacing.extraLargeIncreased

    MouseArea { // Prevent clicks from reaching flickable
        z: 1
        implicitWidth: header.implicitWidth
        implicitHeight: header.implicitHeight - Layout.bottomMargin
        Layout.bottomMargin: -flickable.topMargin // Extra height to block clicks on flickable top margin
        onClicked: focus = true

        RowLayout {
            id: header

            spacing: Tokens.spacing.largeIncreased

            Loader {
                visible: active
                active: root.isSubPage
                asynchronous: true
                sourceComponent: IconButton {
                    icon: "arrow_back"
                    font: Tokens.font.icon.medium
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.nState.closeSubPage()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font: Tokens.font.title.large
                elide: Text.ElideRight
            }
        }
    }

    // Retries until the page has loaded, then flashes the row picked in search
    Timer {
        property int tries

        // Only the page on top of the sub-page stack answers
        running: root.nState.pendingHighlight.length > 0 && root.visible && (root.StackView.index < 0 || root.StackView.index === root.nState.subPageIdxStack.length)
        interval: 150
        repeat: true
        onTriggered: {
            tries++;
            if (tries < 3)
                return; // let the page finish its transition
            if (root.highlightRow(root.nState.pendingHighlight) || tries > 30) {
                root.nState.pendingHighlight = "";
                tries = 0;
            }
        }
        onRunningChanged: tries = 0
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        TapHandler {
            onTapped: flickable.focus = true
        }
    }

    // Brief highlight drawn over the viewport after scrolling to a search result
    StyledRect {
        id: flash

        parent: flickable
        z: 100
        opacity: 0
        visible: opacity > 0
        radius: Tokens.rounding.medium
        color: Colours.palette.m3primary

        SequentialAnimation {
            id: flashAnim

            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0.32
                duration: 160
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0
                duration: 420
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0.32
                duration: 160
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0
                duration: 700
            }
        }
    }
}
