pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool active: BtAgent.active
    property string requestType: BtAgent.requestType

    visible: opacity > 0
    opacity: active ? 1 : 0
    scale: active ? 1 : 0.85

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on scale {
        Anim {}
    }

    // Dim background
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4 * root.opacity)
    }

    // Dialog card
    StyledRect {
        id: card

        anchors.centerIn: parent
        implicitWidth: Math.min(380, root.width - Tokens.padding.extraLarge * 2)
        implicitHeight: cardContent.implicitHeight + Tokens.padding.extraLarge * 2
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainerHigh

        ColumnLayout {
            id: cardContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            // Icon
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    switch (root.requestType) {
                    case "confirmation":
                    case "authorization":
                        return "bluetooth_searching";
                    case "passkey":
                    case "pin":
                        return "pin";
                    case "display":
                        return "bluetooth_connected";
                    default:
                        return "bluetooth";
                    }
                }
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3primary
            }

            // Title
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    switch (root.requestType) {
                    case "confirmation":
                        return qsTr("Confirm pairing");
                    case "passkey":
                        return qsTr("Enter passkey");
                    case "pin":
                        return qsTr("Enter PIN");
                    case "display":
                        return qsTr("Enter on device");
                    case "authorization":
                        return qsTr("Pairing request");
                    default:
                        return qsTr("Bluetooth pairing");
                    }
                }
                font: Tokens.font.title.medium
            }

            // Device name
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                text: BtAgent.deviceName
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            // Passkey display (for confirmation and display modes)
            Loader {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                active: root.requestType === "confirmation" || root.requestType === "display"
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.requestType === "display"
                              ? qsTr("Type this passkey on the device:")
                              : qsTr("Confirm this passkey matches:")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Large passkey digits
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        Repeater {
                            model: BtAgent.passkey.split("")

                            delegate: StyledRect {
                                required property string modelData
                                required property int index

                                implicitWidth: implicitHeight
                                implicitHeight: digitText.implicitHeight + Tokens.padding.medium * 2
                                radius: Tokens.rounding.medium
                                color: {
                                    if (root.requestType === "display" && index < BtAgent.entered)
                                        return Colours.palette.m3primary;
                                    return Colours.palette.m3surfaceContainerHighest;
                                }

                                Behavior on color {
                                    CAnim {}
                                }

                                StyledText {
                                    id: digitText

                                    anchors.centerIn: parent
                                    text: modelData
                                    font: Tokens.font.title.builders.large.weight(Font.Bold).build()
                                    color: {
                                        if (root.requestType === "display" && index < BtAgent.entered)
                                            return Colours.palette.m3onPrimary;
                                        return Colours.palette.m3onSurface;
                                    }

                                    Behavior on color {
                                        CAnim {}
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Input field (for passkey and pin modes)
            Loader {
                id: inputLoader

                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.medium
                active: root.requestType === "passkey" || root.requestType === "pin"
                visible: active

                onActiveChanged: {
                    if (active)
                        focusInputTimer.start();
                }

                sourceComponent: FocusScope {
                    id: inputScope

                    property string inputBuffer: ""

                    implicitHeight: Math.max(48, inputCharList.implicitHeight + Tokens.padding.medium * 2)
                    focus: true
                    activeFocusOnTab: true

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            BtAgent.reject();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (inputBuffer.length > 0) {
                                if (root.requestType === "passkey")
                                    BtAgent.sendPasskey(inputBuffer);
                                else
                                    BtAgent.sendPin(inputBuffer);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backspace) {
                            if (event.modifiers & Qt.ControlModifier)
                                inputBuffer = "";
                            else
                                inputBuffer = inputBuffer.slice(0, -1);
                            event.accepted = true;
                        } else if (event.text && event.text.length > 0) {
                            if (event.key === Qt.Key_Tab) {
                                event.accepted = false;
                                return;
                            }
                            // For passkey, only allow digits and max 6 chars
                            if (root.requestType === "passkey") {
                                if (/^\d$/.test(event.text) && inputBuffer.length < 6)
                                    inputBuffer += event.text;
                            } else {
                                inputBuffer += event.text;
                            }
                            event.accepted = true;
                        }
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.large
                        color: inputScope.activeFocus
                               ? Qt.lighter(Colours.tPalette.m3surfaceContainer, 1.05)
                               : Colours.tPalette.m3surfaceContainer
                        border.width: inputScope.activeFocus ? 4 : 1
                        border.color: inputScope.activeFocus
                                      ? Colours.palette.m3primary
                                      : Colours.palette.m3outline

                        Behavior on border.color {
                            CAnim {}
                        }

                        Behavior on border.width {
                            CAnim {}
                        }

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    StateLayer {
                        hoverEnabled: false
                        cursorShape: Qt.IBeamCursor
                        radius: Tokens.rounding.large
                        onClicked: inputScope.forceActiveFocus()
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: root.requestType === "passkey" ? qsTr("Passkey") : qsTr("PIN")
                        color: Colours.palette.m3outline
                        font: Tokens.font.mono.medium
                        opacity: inputScope.inputBuffer ? 0 : 1

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    ListView {
                        id: inputCharList

                        readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

                        anchors.centerIn: parent
                        implicitWidth: fullWidth
                        implicitHeight: Tokens.font.body.medium.pointSize

                        orientation: Qt.Horizontal
                        spacing: Tokens.spacing.extraSmall
                        interactive: false

                        model: ScriptModel {
                            values: inputScope.inputBuffer.split("")
                        }

                        delegate: StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: inputCharList.implicitHeight
                            color: Colours.palette.m3onSurface
                            radius: Tokens.rounding.medium / 2

                            opacity: 0
                            scale: 0
                            Component.onCompleted: {
                                opacity = 1;
                                scale = 1;
                            }

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                        }

                        Behavior on implicitWidth {
                            Anim {}
                        }
                    }
                }
            }

            Timer {
                id: focusInputTimer

                interval: 150
                onTriggered: {
                    if (inputLoader.item)
                        inputLoader.item.forceActiveFocus();
                }
            }

            // Description for authorization
            Loader {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                active: root.requestType === "authorization"
                visible: active

                sourceComponent: StyledText {
                    text: qsTr("This device wants to pair with your computer. Allow?")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Action buttons
            RowLayout {
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                TextButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Reject")

                    onClicked: BtAgent.reject()
                }

                TextButton {
                    Layout.fillWidth: true
                    Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                    inactiveColour: Colours.palette.m3primary
                    inactiveOnColour: Colours.palette.m3onPrimary
                    text: {
                        switch (root.requestType) {
                        case "confirmation":
                        case "authorization":
                            return qsTr("Accept");
                        case "passkey":
                        case "pin":
                            return qsTr("Submit");
                        case "display":
                            return qsTr("Cancel");
                        default:
                            return qsTr("OK");
                        }
                    }
                    enabled: {
                        if (root.requestType === "passkey" || root.requestType === "pin") {
                            return inputLoader.item?.inputBuffer?.length > 0;
                        }
                        return true;
                    }

                    onClicked: {
                        switch (root.requestType) {
                        case "confirmation":
                        case "authorization":
                            BtAgent.confirm();
                            break;
                        case "passkey":
                            if (inputLoader.item)
                                BtAgent.sendPasskey(inputLoader.item.inputBuffer);
                            break;
                        case "pin":
                            if (inputLoader.item)
                                BtAgent.sendPin(inputLoader.item.inputBuffer);
                            break;
                        case "display":
                            BtAgent.reject();
                            break;
                        }
                    }
                }
            }
        }
    }
}
