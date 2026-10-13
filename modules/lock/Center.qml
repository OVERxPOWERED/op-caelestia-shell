import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale
    property bool patternMode

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: patternMode ? Tokens.spacing.medium : Tokens.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: patternMode ? 0 : Tokens.padding.large
        centerScale: root.patternMode ? root.centerScale * 0.75 : root.centerScale

        Behavior on centerScale {
            Anim {}
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
        
        visible: !root.patternMode
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: (root.patternMode ? Tokens.spacing.small : Tokens.spacing.extraExtraLarge) * root.centerScale
        Layout.bottomMargin: (root.patternMode ? Tokens.spacing.small : Tokens.spacing.extraLarge) * root.centerScale
        centerWidth: root.patternMode ? Math.round(root.centerWidth * 0.45) : root.centerWidth
    }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
        patternMode: root.patternMode
        onPatternModeChanged: root.patternMode = patternMode
    }

    LockActions {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.patternMode ? 0 : -Tokens.spacing.small
        onPowerRequested: root.lock.requestPowerConfirm()
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
