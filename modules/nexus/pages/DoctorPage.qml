pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Health checks for the things that have gone wrong before. The checks themselves live in
// scripts/doctor.py; they only read state, and a fix is offered only where it is safe.
PageBase {
    id: root

    property var checks: []
    property bool checking: false
    property string fixing
    property string note

    readonly property int problems: checks.filter(c => c.status === "warn" || c.status === "bad").length
    readonly property string script: Quickshell.shellPath("scripts/doctor.py")

    function statusIcon(status: string): string {
        return status === "ok" ? "check_circle" : status === "warn" ? "warning" : status === "bad" ? "error" : "info";
    }

    function statusColour(status: string): color {
        return status === "ok" ? Colours.palette.m3primary : status === "warn" ? Colours.palette.m3tertiary : status === "bad" ? Colours.palette.m3error : Colours.palette.m3outline;
    }

    function recheck(): void {
        if (checking)
            return;
        checking = true;
        checkProc.running = true;
    }

    function fix(id: string, arg: string): void {
        fixing = id + arg;
        fixProc.command = ["python3", script, "fix", id].concat(arg ? [arg] : []);
        fixProc.running = true;
    }

    title: Tr.tr("Doctor")
    Component.onCompleted: recheck()

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: checkProc

            command: ["python3", root.script, "check"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.checks = JSON.parse(text);
                    } catch (e) {
                        root.checks = [];
                        root.note = Tr.tr("The checks could not run");
                    }
                    root.checking = false;
                }
            }
        }

        Process {
            id: fixProc

            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.note = JSON.parse(text).message;
                    } catch (e) {
                        root.note = Tr.tr("The fix did not report back");
                    }
                    root.fixing = "";
                    root.checking = false;
                    root.recheck();
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: summary.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: summary

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: root.checking && root.checks.length === 0 ? "pending" : root.problems === 0 ? "health_and_safety" : "medical_services"
                    color: root.checking ? Colours.palette.m3outline : root.problems === 0 ? Colours.palette.m3primary : Colours.palette.m3tertiary
                    fontStyle: Tokens.font.icon.large
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: root.checking && root.checks.length === 0 ? Tr.tr("Checking…") : root.problems === 0 ? Tr.tr("Everything looks fine") : root.problems === 1 ? Tr.tr("1 thing needs a look") : Tr.tr("%1 things need a look").arg(root.problems)
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.note || Tr.tr("Checks only read your system. Nothing changes unless you press a fix.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                TextButton {
                    text: root.checking ? Tr.tr("Checking…") : Tr.tr("Check again")
                    disabled: root.checking
                    onClicked: {
                        root.note = "";
                        root.recheck();
                    }
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Checks")
        }

        Repeater {
            model: root.checks

            ConnectedRect {
                id: row

                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === root.checks.length - 1
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignTop
                        text: root.statusIcon(row.modelData.status)
                        color: root.statusColour(row.modelData.status)
                        fontStyle: Tokens.font.icon.small
                        fill: 1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.title
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.detail
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: !!row.modelData.hint
                            text: row.modelData.hint ?? ""
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }

                        // Things the check found that you can act on one by one
                        Repeater {
                            model: row.modelData.items

                            RowLayout {
                                id: item

                                required property var modelData
                                property bool armed

                                Layout.fillWidth: true
                                Layout.topMargin: Tokens.spacing.small
                                spacing: Tokens.spacing.medium

                                Timer {
                                    running: item.armed
                                    interval: 4000
                                    onTriggered: item.armed = false
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: item.modelData.label
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: item.modelData.sub
                                        color: Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }

                                TextButton {
                                    visible: !!item.modelData.keepArg
                                    type: TextButton.Text
                                    text: Tr.tr("Keep")
                                    disabled: root.fixing !== "" || root.checking
                                    onClicked: root.fix("keep", item.modelData.keepArg)
                                }

                                TextButton {
                                    type: TextButton.Tonal
                                    text: root.fixing === item.modelData.fix + item.modelData.arg ? Tr.tr("Working…") : item.armed ? Tr.tr("Sure?") : item.modelData.fixLabel
                                    disabled: root.fixing !== "" || root.checking
                                    onClicked: {
                                        if (item.modelData.confirm && !item.armed) {
                                            item.armed = true;
                                            return;
                                        }
                                        item.armed = false;
                                        root.fix(item.modelData.fix, item.modelData.arg);
                                    }
                                }
                            }
                        }
                    }

                    TextButton {
                        Layout.alignment: Qt.AlignVCenter
                        visible: !!row.modelData.fix
                        text: root.fixing === row.modelData.fix ? Tr.tr("Working…") : row.modelData.fixLabel ?? Tr.tr("Fix")
                        disabled: root.fixing !== "" || root.checking
                        onClicked: root.fix(row.modelData.fix, "")
                    }
                }
            }
        }
    }
}
