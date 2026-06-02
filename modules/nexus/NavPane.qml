import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: Tokens.spacing.large

    NavLocations {
        Layout.fillWidth: true
        Layout.fillHeight: true
        nState: root.nState
    }
}
