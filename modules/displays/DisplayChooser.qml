pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services

// "What should this display do?", shown when a new display is plugged in. Keyboard first:
// arrows or Tab to move, 1-4 to pick directly, Enter to apply, Esc to leave things as they are.
Scope {
    id: chooserScope

    readonly property var options: [
        {
            kind: "extend",
            icon: "splitscreen_left",
            label: Tr.tr("Extend"),
            hint: Tr.tr("Use it as a second screen")
        },
        {
            kind: "mirror",
            icon: "cast",
            label: Tr.tr("Mirror"),
            hint: Tr.tr("Show the same picture")
        },
        {
            kind: "external",
            icon: "desktop_windows",
            label: Tr.tr("Display only"),
            hint: Tr.tr("Turn the laptop screen off")
        },
        {
            kind: "laptop",
            icon: "laptop",
            label: Tr.tr("Laptop only"),
            hint: Tr.tr("Ignore the new display")
        }
    ]

    Variants {
        model: Screens.screens

        LazyLoader {
            id: loader

            required property ShellScreen modelData

            // Not while a change is waiting to be confirmed: that dialog takes over
            active: Displays.chooser !== null && !Displays.pending && modelData.name === (Hypr.focusedMonitor?.name ?? modelData.name)

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

                    property int current: 0

                    function pick(index: int): void {
                        Displays.chooseLayout(chooserScope.options[index].kind);
                    }

                    anchors.fill: parent
                    focus: true
                    opacity: 0
                    Component.onCompleted: {
                        forceActiveFocus();
                        opacity = 1;
                    }

                    Keys.onPressed: event => {
                        const n = chooserScope.options.length;
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
                            current = (current + n - 1) % n;
                        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            current = (current + 1) % n;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            pick(current);
                        } else if (event.key === Qt.Key_Escape) {
                            Displays.dismissChooser();
                        } else if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + n) {
                            pick(event.key - Qt.Key_1);
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

                    // Clicking outside the card leaves things as they are
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Displays.dismissChooser()
                    }

                    StyledRect {
                        id: card

                        anchors.centerIn: parent
                        implicitWidth: content.implicitWidth + Tokens.padding.extraLarge * 2
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

                        // Swallow clicks on the card itself
                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            id: content

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.large

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                MaterialIcon {
                                    text: "cast_connected"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.large
                                }

                                ColumnLayout {
                                    spacing: 0

                                    StyledText {
                                        text: Tr.tr("New display connected")
                                        font: Tokens.font.title.medium
                                    }

                                    StyledText {
                                        text: Displays.chooser?.description ?? ""
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                    }
                                }
                            }

                            RowLayout {
                                spacing: Tokens.spacing.medium

                                Repeater {
                                    model: chooserScope.options

                                    StyledRect {
                                        id: tile

                                        required property var modelData
                                        required property int index
                                        readonly property bool selected: index === root.current

                                        implicitWidth: 158
                                        implicitHeight: 152
                                        radius: Tokens.rounding.large
                                        color: selected ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                                        border.width: selected ? 2 : 0
                                        border.color: Colours.palette.m3primary

                                        StateLayer {
                                            onClicked: root.pick(tile.index)
                                        }

                                        ColumnLayout {
                                            id: tileColumn

                                            anchors.centerIn: parent
                                            width: parent.width - Tokens.padding.medium * 2
                                            spacing: Tokens.spacing.small

                                            MaterialIcon {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: tile.modelData.icon
                                                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                fontStyle: Tokens.font.icon.large
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: `${tile.index + 1}  ${tile.modelData.label}`
                                                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                font: Tokens.font.label.large
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: tile.modelData.hint
                                                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                                font: Tokens.font.label.small
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Tr.tr("← → choose · 1–4 pick · Enter apply · Esc leave as it is")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }
            }
        }
    }
}
