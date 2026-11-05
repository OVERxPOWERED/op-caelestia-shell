pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Full-screen overlay on every monitor while ShutdownScreen.active: a plain dark backdrop, the
// logo, a spinner and a short label.
Variants {
    model: Screens.screens

    LazyLoader {
        id: loader

        required property ShellScreen modelData

        active: ShutdownScreen.active

        StyledWindow {
            screen: loader.modelData
            name: "shutdown"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Rectangle {
                id: backdrop

                anchors.fill: parent
                color: "black"
                opacity: 0

                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: ShutdownScreen.fadeMs
                        easing.type: Easing.InOutQuad
                    }
                }

                // Swallow clicks so nothing underneath is hit while shutting down
                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.large

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96
                        height: 96

                        Image {
                            id: logo

                            anchors.fill: parent
                            source: Qt.resolvedUrl("../../assets/logo.svg")
                            sourceSize.width: 96
                            sourceSize.height: 96
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        // The logo is dark, so tint it to read on the black backdrop
                        ColorOverlay {
                            anchors.fill: logo
                            source: logo
                            color: Qt.rgba(1, 1, 1, 0.9)
                        }
                    }

                    CircularIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: true
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ShutdownScreen.label
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                }
            }
        }
    }
}
