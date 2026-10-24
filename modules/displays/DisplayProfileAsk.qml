pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// "Apply this saved layout?" with Yes and No, shown before a layout chosen in Nexus is applied.
// Enter or Y applies, Esc or N cancels; arrows switch between the two buttons.
Scope {
    Variants {
        model: Screens.screens

        LazyLoader {
            id: loader

            required property ShellScreen modelData

            active: Displays.profileToApply !== null && !Displays.pending && Displays.chooser === null && modelData.name === (Hypr.focusedMonitor?.name ?? modelData.name)

            StyledWindow {
                id: win

                screen: loader.modelData
                // Same layer name as the confirmation dialog, so it gets the same blur rule
                name: "display-confirm"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Item {
                    id: root

                    // 0 = No, 1 = Yes; start on No so a stray Enter cannot change the layout
                    property int current: 0

                    anchors.fill: parent
                    focus: true
                    opacity: 0
                    Component.onCompleted: {
                        forceActiveFocus();
                        opacity = 1;
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            current = 1 - current;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Displays.answerProfile(current === 1);
                        } else if (event.key === Qt.Key_Y) {
                            Displays.answerProfile(true);
                        } else if (event.key === Qt.Key_N || event.key === Qt.Key_Escape) {
                            Displays.answerProfile(false);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.32)
                    }

                    // Clicking outside the card means No
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Displays.answerProfile(false)
                    }

                    StyledRect {
                        id: card

                        anchors.centerIn: parent
                        implicitWidth: Math.max(content.implicitWidth, 380) + Tokens.padding.extraLarge * 2
                        implicitHeight: content.implicitHeight + Tokens.padding.extraLarge * 2

                        color: Qt.alpha(Colours.palette.m3surfaceContainer, Colours.transparency.enabled ? 0.72 : 1)
                        radius: Tokens.rounding.extraLarge
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                        scale: root.opacity < 1 ? 0.94 : 1

                        Behavior on scale {
                            Anim {
                                type: Anim.DefaultSpatial
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            id: content

                            anchors.centerIn: parent
                            width: parent.width - Tokens.padding.extraLarge * 2
                            spacing: Tokens.spacing.large

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                MaterialIcon {
                                    text: "bookmark"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.large
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Tr.tr("Apply this layout?")
                                        font: Tokens.font.title.medium
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Displays.profileToApply?.name ?? ""
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.medium
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: (Displays.profileToApply?.outputs ?? []).map(o => o.name).join(" · ")
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("You can still go back afterwards: the layout is only kept if you confirm it.")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Tr.tr("Y apply · N or Esc cancel")
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }

                                TextButton {
                                    text: Tr.tr("No")
                                    type: root.current === 0 ? TextButton.Filled : TextButton.Tonal
                                    onClicked: Displays.answerProfile(false)
                                }

                                TextButton {
                                    text: Tr.tr("Yes")
                                    type: root.current === 1 ? TextButton.Filled : TextButton.Tonal
                                    onClicked: Displays.answerProfile(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
