pragma ComponentBehavior: Bound

import "."
import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property DevSession session

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Debug Panel")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        // Action Buttons Section
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: buttonsLayout.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: buttonsLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Actions")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    TextButton {
                        text: qsTr("Clear Log")
                        onClicked: {
                            debugOutput.text = "";
                            appendLog("Debug log cleared");
                        }
                    }

                    TextButton {
                        text: qsTr("Test Action")
                        onClicked: {
                            appendLog("Test action executed at " + new Date().toLocaleTimeString());
                        }
                    }

                    TextButton {
                        text: qsTr("Log Network State")
                        onClicked: {
                            appendLog("Network state:");
                            appendLog("  Active: " + (root.session.network.active ? "Yes" : "No"));
                        }
                    }
                }
            }
        }

        // Debug Output Section
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Debug Output")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Copy")
                        onClicked: {
                            debugOutput.selectAll();
                            debugOutput.copy();
                            debugOutput.deselect();
                            appendLog("Output copied to clipboard");
                        }
                    }
                }

                StyledFlickable {
                    id: flickable

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: debugOutput.implicitHeight

                    TextEdit {
                        id: debugOutput

                        width: flickable.width
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        font.family: Appearance.font.family.mono
                        font.pointSize: Appearance.font.size.smaller
                        renderType: TextEdit.NativeRendering
                        textFormat: TextEdit.PlainText
                        color: "#ffb0ca"  // Use primary color - will be set programmatically
                        
                        Component.onCompleted: {
                            color = Colours.palette.m3primary;
                            appendLog("Debug panel initialized");
                        }

                        onTextChanged: {
                            // Ensure color stays set when text changes
                            color = Colours.palette.m3primary;
                            if (flickable.contentHeight > flickable.height) {
                                flickable.contentY = flickable.contentHeight - flickable.height;
                            }
                        }
                    }
                }

                StyledScrollBar {
                    flickable: flickable
                    policy: ScrollBar.AlwaysOn
                }
            }
        }
    }

    function appendLog(message: string): void {
        const timestamp = new Date().toLocaleTimeString();
        debugOutput.text += `[${timestamp}] ${message}\n`;
    }

    function log(message: string): void {
        appendLog(message);
    }
}

