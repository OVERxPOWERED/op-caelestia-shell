import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    property Item blurSource: null
    property real absX: 0
    property real absY: 0
    property bool hideClockOverride: false
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale
    property bool patternMode

    width: centerWidth
    spacing: patternMode ? Tokens.spacing.medium : Tokens.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.large
        visible: Config.lock.showClock && !root.hideClockOverride
        centerScale: root.centerScale
        centerWidth: root.centerWidth
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()

        visible: Config.lock.showClock && !root.hideClockOverride
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: (root.patternMode ? Tokens.spacing.small : Tokens.spacing.extraExtraLarge) * root.centerScale
        Layout.bottomMargin: (root.patternMode ? Tokens.spacing.small : Tokens.spacing.extraLarge) * root.centerScale
        visible: Config.lock.showProfile
        centerWidth: root.centerWidth

        Behavior on Layout.topMargin {
            Anim {}
        }

        Behavior on Layout.bottomMargin {
            Anim {}
        }
    }

    PasswordInput {
        id: passwordInput

        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
        blurSource: root.blurSource
        absX: root.absX + x
        absY: root.absY + y
        patternMode: root.patternMode
        onPatternModeChanged: root.patternMode = patternMode
    }

    LockActions {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.patternMode ? 0 : -Tokens.spacing.small
        visible: Config.lock.showActions
        blurSource: root.blurSource
        absX: root.absX + x
        absY: root.absY + y
        onPowerRequested: root.lock.requestPowerConfirm()
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
