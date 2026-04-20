pragma ComponentBehavior: Bound

import ".."
import "../../../launcher/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

CollapsibleSection {
    title: qsTr("Color variant")
    description: qsTr("Material theme variant")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: M3Variants.list

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Tokens.rounding.large
                border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                border.color: Colours.palette.m3primary
                implicitHeight: variantRow.implicitHeight + Tokens.padding.medium * 2

                StateLayer {
                    onClicked: {
                        const variant = modelData.variant;

                        Schemes.currentVariant = variant;
                        Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);

                        Qt.callLater(() => {
                            reloadTimer.restart();
                        });
                    }
                }

                Timer {
                    id: reloadTimer

                    interval: 300
                    onTriggered: {
                        Schemes.reload();
                    }
                }

                RowLayout {
                    id: variantRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.medium

                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: modelData.icon
                        font: Tokens.font.icon.large
                        fill: modelData.variant === Schemes.currentVariant ? 1 : 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        font: modelData.variant === Schemes.currentVariant ? Tokens.font.body.builders.small.weight(500).build() : Tokens.font.body.builders.small.weight(400).build()
                    }

                    MaterialIcon {
                        visible: modelData.variant === Schemes.currentVariant
                        text: "check"
                        color: Colours.palette.m3primary
                        font: Tokens.font.icon.large
                    }
                }
            }
        }
    }
}
