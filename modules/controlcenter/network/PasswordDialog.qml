pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var network: session.network.pendingNetwork

    visible: session.network.showPasswordDialog
    enabled: visible
    focus: visible

    Keys.onEscapePressed: {
        root.session.network.showPasswordDialog = false;
        passwordField.text = "";
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.session.network.showPasswordDialog = false;
                passwordField.text = "";
            }
        }
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent

        implicitWidth: 400
        implicitHeight: content.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surface
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
            }
        }

        Keys.onEscapePressed: {
            root.session.network.showPasswordDialog = false;
            passwordField.text = "";
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                font.pointSize: Appearance.font.size.extraLarge * 2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enter password")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.network ? qsTr("Network: %1").arg(root.network.ssid) : ""
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            Item {
                Layout.topMargin: Appearance.spacing.large
                Layout.fillWidth: true
                implicitHeight: passwordField.implicitHeight + Appearance.padding.normal * 2

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                    Behavior on border.color {
                        CAnim {}
                    }
                }

                StyledTextField {
                    id: passwordField

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal

                    echoMode: TextField.Password
                    placeholderText: qsTr("Password")

                    Component.onCompleted: {
                        if (root.visible) {
                            forceActiveFocus();
                        }
                    }

                    Connections {
                        target: root
                        function onVisibleChanged(): void {
                            if (root.visible) {
                                passwordField.forceActiveFocus();
                                passwordField.text = "";
                            }
                        }
                    }

                    Keys.onReturnPressed: {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                    }
                    Keys.onEnterPressed: {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Appearance.spacing.normal
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Button {
                    id: cancelButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")

                    function onClicked(): void {
                        root.session.network.showPasswordDialog = false;
                        passwordField.text = "";
                    }
                }

                Button {
                    id: connectButton

                    Layout.fillWidth: true
                    color: Colours.palette.m3primary
                    onColor: Colours.palette.m3onPrimary
                    text: qsTr("Connect")
                    enabled: passwordField.text.length > 0

                    function onClicked(): void {
                        if (root.network && passwordField.text.length > 0) {
                            Network.connectToNetwork(root.network.ssid, passwordField.text);
                            root.session.network.showPasswordDialog = false;
                            passwordField.text = "";
                        }
                    }
                }
            }
        }
    }

    component Button: StyledRect {
        property color onColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text
        property alias enabled: stateLayer.enabled

        function onClicked(): void {
        }

        radius: Appearance.rounding.small
        implicitHeight: label.implicitHeight + Appearance.padding.small * 2
        opacity: enabled ? 1 : 0.5

        StateLayer {
            id: stateLayer

            enabled: parent.enabled
            color: parent.onColor

            function onClicked(): void {
                if (enabled) {
                    parent.onClicked();
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            animate: true
            color: parent.onColor
            font.pointSize: Appearance.font.size.normal
        }
    }
}

