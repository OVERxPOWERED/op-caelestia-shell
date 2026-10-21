import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: Tokens.spacing.large

    SearchBar {
        id: searchField

        Layout.fillWidth: true

        placeholderText: Tr.tr("Search settings")
        font: Tokens.font.body.large

        bg.color: Colours.tPalette.m3surfaceContainerLowest
        bg.border.color: Colours.palette.m3outlineVariant
        searchIcon.fontStyle: Tokens.font.icon.medium
        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
        clearIcon.font: Tokens.font.icon.medium
        clearIcon.padding: Tokens.padding.extraSmall

        Behavior on bg.border.color {
            CAnim {}
        }

        Keys.onDownPressed: root.nState.searchMove(1)
        Keys.onUpPressed: root.nState.searchMove(-1)
        Keys.onReturnPressed: root.nState.searchActivate()
        Keys.onEnterPressed: root.nState.searchActivate()
        Keys.onEscapePressed: event => {
            if (text.length > 0)
                clear();
            else
                event.accepted = false;
        }

        Binding {
            target: root.nState
            property: "searchOpen"
            value: searchField.text.length > 0
        }

        Binding {
            target: root.nState
            property: "searchText"
            value: searchField.text
        }

        Connections {
            function onFocusSearch(): void {
                searchField.forceActiveFocus();
                searchField.selectAll();
            }

            function onClearSearch(): void {
                searchField.clear();
            }

            target: root.nState
        }
    }

    NavLocations {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
    }
}
