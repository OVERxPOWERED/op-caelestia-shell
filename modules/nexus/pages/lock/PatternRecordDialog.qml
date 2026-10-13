pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.lock.center

Item {
    id: root

    property string step: "first" // "first" | "confirm"
    property string recordedPattern: ""
    property string statusText: qsTr("Draw your new unlock pattern (at least 4 dots)")
    property bool isErrorText: false

    signal finished(bool success)

    implicitWidth: 320
    implicitHeight: 380

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 280
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.statusText
            color: root.isErrorText ? Colours.palette.m3error : Colours.palette.m3onSurface
            font: Tokens.font.body.medium
        }

        PatternGrid {
            id: grid
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 220
            implicitHeight: 220

            onPatternFinished: code => {
                if (code.length < 4) {
                    root.isErrorText = true;
                    root.statusText = qsTr("Pattern too short! Must connect at least 4 dots.");
                    grid.triggerError();
                    return;
                }

                if (root.step === "first") {
                    root.recordedPattern = code;
                    root.step = "confirm";
                    root.isErrorText = false;
                    root.statusText = qsTr("Draw pattern again to confirm");
                    grid.clearPattern();
                } else if (root.step === "confirm") {
                    if (code === root.recordedPattern) {
                        GlobalConfig.lock.pattern = code;
                        Toaster.toast(qsTr("Pattern Lock"), qsTr("New unlock pattern saved successfully"), "lock");
                        root.finished(true);
                    } else {
                        root.isErrorText = true;
                        root.statusText = qsTr("Patterns did not match! Try again.");
                        root.step = "first";
                        root.recordedPattern = "";
                        grid.triggerError();
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.medium

            IconTextButton {
                text: qsTr("Clear")
                icon: "refresh"
                type: IconTextButton.Text
                onClicked: {
                    root.step = "first";
                    root.recordedPattern = "";
                    root.isErrorText = false;
                    root.statusText = qsTr("Draw your new unlock pattern");
                    grid.clearPattern();
                }
            }

            IconTextButton {
                text: qsTr("Cancel")
                icon: "close"
                type: IconTextButton.Text
                onClicked: root.finished(false)
            }
        }
    }
}
