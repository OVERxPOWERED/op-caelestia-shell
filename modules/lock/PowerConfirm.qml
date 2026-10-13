pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property bool active
    property Item blurSource

    signal cancelled
    signal accepted

    function cancel(): void {
        cancelled();
    }

    function accept(): void {
        accepted();
        Quickshell.execDetached(Config.session.commands.shutdown);
    }

    anchors.fill: parent
    visible: opacity > 0
    enabled: visible
    opacity: active ? 1 : 0
    z: 100
    focus: active

    onActiveChanged: if (active)
        forceActiveFocus()

    Keys.onEscapePressed: root.cancel()
    Keys.onReturnPressed: root.accept()
    Keys.onEnterPressed: root.accept()

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.cancel()

        StyledRect {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.36)
        }
    }

    StyledRect {
        id: panel

        anchors.centerIn: parent
        implicitWidth: Math.min(root.width - Tokens.padding.extraLarge * 2, content.implicitWidth + Tokens.padding.extraLarge * 3)
        implicitHeight: content.implicitHeight + Tokens.padding.extraLarge * 2
        radius: Tokens.rounding.extraLarge
        color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.4)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 30
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.8)
        }

        ShaderEffectSource {
            id: glassCapture
            sourceItem: root.blurSource
            sourceRect: Qt.rect(
                root.blurSource ? (root.blurSource.width - panel.width) / 2 : 0,
                root.blurSource ? (root.blurSource.height - panel.height) / 2 : 0,
                panel.width,
                panel.height
            )
            visible: false 
        }

        FastBlur {
            id: glassBlur
            anchors.fill: parent
            source: glassCapture
            radius: 75
            visible: false
        }

        StyledRect {
            id: glassMask
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            z: -1
            source: glassBlur
            maskSource: glassMask
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            id: content

            anchors.centerIn: parent
            spacing: Tokens.spacing.large

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "warning"
                color: Colours.palette.m3error
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Shut down the system?")
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.medium
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.medium

                ConfirmButton {
                    text: qsTr("Cancel")
                    colour: Colours.tPalette.m3surfaceContainerHighest
                    onColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.cancel()
                }

                ConfirmButton {
                    text: qsTr("Shut Down")
                    colour: Colours.palette.m3error
                    onColour: Colours.palette.m3onError
                    onClicked: root.accept()
                }
            }
        }
    }

    component ConfirmButton: StyledRect {
        id: button

        required property string text
        required property color colour
        required property color onColour

        signal clicked

        implicitWidth: label.implicitWidth + Tokens.padding.large * 2
        implicitHeight: label.implicitHeight + Tokens.padding.medium
        radius: Tokens.rounding.full
        color: colour

        StateLayer {
            radius: parent.radius
            onClicked: button.clicked()
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            text: button.text
            color: button.onColour
            font: Tokens.font.label.large
        }
    }
}
