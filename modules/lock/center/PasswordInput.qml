pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property real centerScale
    required property int centerWidth
    required property var lock
    property bool patternMode

    readonly property int patternSize: Math.max(180, Math.min(240, Math.round(centerWidth * 0.42)))
    readonly property string patternCode: GlobalConfig.lock.pattern ?? "74159"
    readonly property bool patternAvailable: true

    onPatternAvailableChanged: {
        if (!patternAvailable)
            patternMode = false;
    }

    implicitWidth: {
        const w = centerWidth * 0.8;
        if (patternMode)
            return w;
        const patternToggleWidth = patternAvailable ? patternToggle.implicitWidth + inputRow.spacing : 0;
        return lock.pam.buffer ? w : Math.min(w, inputField.placeholderWidth + iconWrapper.implicitWidth + patternToggleWidth + enterButton.implicitWidth + inputRow.spacing * 2 + Tokens.padding.medium * 2);
    }
    implicitHeight: input.implicitHeight + Tokens.padding.extraSmall * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: patternMode ? Tokens.rounding.extraLarge : Tokens.rounding.full

    focus: true
    onActiveFocusChanged: {
        if (!activeFocus)
            forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (root.lock.unlocking)
            return;

        if (root.patternMode) {
            if (event.key === Qt.Key_Escape) {
                root.patternMode = false;
                event.accepted = true;
            }
            return;
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
            inputField.placeholder.animate = false;

        root.lock.pam.handleKey(event);
    }

    Behavior on implicitWidth {
        Anim {}
    }

    StateLayer {
        hoverEnabled: false
        cursorShape: root.patternMode ? Qt.ArrowCursor : Qt.IBeamCursor
        onClicked: parent.forceActiveFocus()
    }

    ColumnLayout {
        id: input

        anchors.centerIn: parent
        width: parent.width - Tokens.padding.extraSmall * 2
        spacing: Tokens.spacing.medium

        PatternGrid {
            id: patternGrid

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.patternSize
            Layout.preferredHeight: root.patternMode && root.patternAvailable ? root.patternSize : 0
            visible: root.patternMode && root.patternAvailable
            opacity: root.patternMode && root.patternAvailable ? 1 : 0

            onPatternFinished: code => {
                if (code === root.patternCode) {
                    root.lock.lock.unlock();
                    return;
                }

                triggerError();
                root.lock.pam.rejectPattern();
            }

            Behavior on Layout.preferredHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        RowLayout {
            id: inputRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

        Item {
            id: iconWrapper

            Layout.fillHeight: true
            implicitWidth: height

            AnimLoader {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: sourceComponent === iconComp ? 1 : 0
                sourceComp: root.lock.pam.passwd.active || root.lock.pam.howdy.active ? loadingComp : iconComp
            }

            Component {
                id: iconComp

                MaterialIcon {
                    animate: true
                    text: {
                        if (root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries) {
                            if (root.lock.pam.howdy.canAttempt)
                                return "face";
                            return "fingerprint_off";
                        }
                        if (root.lock.pam.fprint.active)
                            return "fingerprint";
                        if (root.lock.pam.howdy.canAttempt)
                            return "face";
                        return "lock";
                    }
                    color: !root.lock.pam.howdy.canAttempt && root.lock.pam.fprint.tries >= GlobalConfig.lock.maxFprintTries ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
                    fill: text === "face"
                }
            }

            Component {
                id: loadingComp

                LoadingIndicator {
                    implicitSize: iconWrapper.height - Tokens.padding.small * 2
                }
            }
        }

        InputField {
            id: inputField

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.patternMode

            centerScale: root.centerScale
            pam: root.lock.pam
        }

        Item {
            Layout.fillWidth: true
            visible: root.patternMode
        }

        IconButton {
            id: patternToggle

            visible: root.patternAvailable
            type: IconButton.Text
            icon: root.patternMode ? "keyboard" : "grid_view"
            checked: root.patternMode
            isToggle: true
            isRound: true
            font: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
            onClicked: {
                root.patternMode = !root.patternMode;
                if (!root.patternMode)
                    patternGrid.clearPattern();
            }
        }

        Item {
            id: enterButton

            visible: !root.patternMode
            implicitWidth: implicitHeight
            implicitHeight: {
                const h = enterIcon.implicitHeight + Tokens.padding.extraSmall * 2;
                return h % 2 === 0 ? h : h + 1;
            }

            MaterialShape {
                anchors.fill: parent

                color: root.lock.pam.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                shape: root.lock.pam.buffer ? MaterialShape.Arrow : MaterialShape.Circle
                scale: !root.lock.pam.buffer ? 1 : mouse.pressed ? 0.6 : mouse.containsMouse ? 0.8 : 0.7
                rotation: 90

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.lock.pam.buffer ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.lock.pam.buffer && root.lock.pam.passwd.start()
                }
            }

            MaterialIcon {
                id: enterIcon

                anchors.centerIn: parent
                text: "arrow_forward"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale * 1.2).build()
                opacity: root.lock.pam.buffer ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
        }
    }
}
