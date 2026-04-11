import QtQuick.Layouts
import qs.components
import qs.services
import Caelestia.Config

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        text: qsTr("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: qsTr("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
    }
}
