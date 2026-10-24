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

// "Keep these display settings?" shown over everything, centred on the focused
// screen, while a display change waits for confirmation.
Scope {
    id: root

    // Blur and translucency for the dialog's layer; mirrors Colours.reloadHyprRules for the
    // shell's own layers and follows the transparency setting
    function applyBlurRule(): void {
        const enabled = Colours.transparency.enabled;
        const ignoreAlpha = Math.min(0.57, Math.max(0, Colours.transparency.base - 0.03));
        const ns = "caelestia-display-confirm";
        Hypr.extras.batchMessage(Hypr.usingLua ? [`eval hl.layer_rule({ match = { namespace = "${ns}" }, blur = ${enabled} })`, `eval hl.layer_rule({ match = { namespace = "${ns}" }, ignore_alpha = ${ignoreAlpha} })`] : [`keyword layerrule blur ${enabled ? 1 : 0}, match:namespace ${ns}`, `keyword layerrule ignore_alpha ${ignoreAlpha}, match:namespace ${ns}`]);
    }

    Component.onCompleted: applyBlurRule()

    Connections {
        function onConfigReloaded(): void {
            root.applyBlurRule(); // a Hyprland reload drops rules added at runtime
        }

        target: Hypr
    }

    Connections {
        function onEnabledChanged(): void {
            root.applyBlurRule();
        }

        function onBaseChanged(): void {
            root.applyBlurRule();
        }

        target: Colours.transparency
    }

    Variants {
        model: Screens.screens

        LazyLoader {
            id: loader

            required property ShellScreen modelData

            // Only the screen you are working on; with one screen focus is moot
            active: Displays.pending && modelData.name === (Hypr.focusedMonitor?.name ?? modelData.name)

            StyledWindow {
                id: win

                screen: loader.modelData
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

                    anchors.fill: parent
                    focus: true
                    opacity: 0
                    Component.onCompleted: {
                        forceActiveFocus();
                        opacity = 1;
                    }

                    Keys.onReturnPressed: Displays.keep()
                    Keys.onEnterPressed: Displays.keep()
                    Keys.onEscapePressed: Displays.revert()

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    // Dims the desktop; too faint to be blurred itself
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.32)
                    }

                    // Swallow clicks outside the card so nothing underneath is hit by accident
                    MouseArea {
                        anchors.fill: parent
                    }

                    StyledRect {
                        id: card

                        anchors.centerIn: parent
                        implicitWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, 460)
                        implicitHeight: content.implicitHeight + Tokens.padding.extraLarge * 2

                        // Translucent so the compositor blurs what is behind it (solid if transparency is off)
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

                        ColumnLayout {
                            id: content

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.extraLarge
                            spacing: Tokens.spacing.large

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.large

                                // Time left, as a ring
                                Item {
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 64

                                    CircularProgress {
                                        anchors.fill: parent
                                        implicitSize: 64
                                        strokeWidth: 5
                                        value: Displays.countdown / Displays.confirmSeconds
                                        fgColour: Displays.countdown <= 5 ? Colours.palette.m3error : Colours.palette.m3primary
                                        bgColour: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Displays.countdown
                                        font: Tokens.font.title.medium
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.extraSmall

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Tr.tr("Keep these display settings?")
                                        font: Tokens.font.title.medium
                                        wrapMode: Text.WordWrap
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Tr.tr("Going back automatically in %1 s").arg(Displays.countdown)
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: Displays.pendingSummary.length > 0
                                text: Displays.pendingSummary
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.mono.small
                                wrapMode: Text.WordWrap
                                maximumLineCount: 5
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Tr.tr("Enter to keep · Esc to go back")
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }

                                TextButton {
                                    text: Tr.tr("Revert")
                                    type: TextButton.Tonal
                                    onClicked: Displays.revert()
                                }

                                TextButton {
                                    text: Tr.tr("Keep")
                                    type: TextButton.Filled
                                    onClicked: Displays.keep()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
