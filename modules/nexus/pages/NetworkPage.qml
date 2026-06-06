pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    signal networkSelected(ap: Nmcli.AccessPoint)

    title: qsTr("Network")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            running: root.visible
            repeat: true
            triggeredOnStart: true
            interval: GlobalConfig.nexus.networkRescanInterval
            onTriggered: Nmcli.rescanWifi()
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Wi-Fi")
            font: Tokens.font.title.medium
            checked: Nmcli.wifiEnabled
            onToggled: Nmcli.enableWifi(checked)

            horizontalPadding: Tokens.padding.largeIncreased
            verticalPadding: Tokens.padding.large
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: networkList.contentHeight + (Nmcli.scanning ? Tokens.rounding.extraSmall : 0) // Inline so it isn't affected by anim
            radius: Tokens.rounding.extraSmall
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            Behavior on implicitHeight {
                Anim {}
            }

            ListView {
                id: networkList

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: scanningIndicator.bottom
                anchors.bottom: parent.bottom

                spacing: 0
                interactive: false

                model: ScriptModel {
                    values: [...Nmcli.networks].sort((a, b) => {
                        if (a.active)
                            return -1;
                        if (b.active)
                            return 1;
                        return b.strength - a.strength;
                    })
                }

                add: Transition {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                }

                remove: Transition {
                    Anim {
                        property: "opacity"
                        to: 0
                        type: Anim.DefaultEffects
                    }
                }

                move: Transition {
                    Anim {
                        property: "opacity"
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        property: "y"
                    }
                }

                displaced: Transition {
                    Anim {
                        property: "opacity"
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        property: "y"
                    }
                }

                delegate: StateLayer {
                    id: network

                    required property Nmcli.AccessPoint modelData
                    readonly property Component rightComp: Nmcli.connectingSsid() === modelData.ssid ? loadingComp : iconComp
                    property bool isComplete
                    property real textOpacity: disabled ? 0.5 : 1

                    anchors.left: networkList.contentItem.left
                    anchors.right: networkList.contentItem.right
                    implicitHeight: networkLayout.implicitHeight + networkLayout.anchors.margins * 2
                    radius: Tokens.rounding.extraSmall
                    anchors.fill: undefined

                    onClicked: {
                        if (!modelData.active) {
                            NetworkConnection.handleConnect(modelData);
                            disabled = true;
                            root.networkSelected(modelData);
                        }
                    }

                    Component.onCompleted: isComplete = true
                    onRightCompChanged: {
                        if (isComplete)
                            rightCompAnim.restart();
                    }

                    Behavior on textOpacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Connections {
                        function onActiveChanged(): void {
                            if (network.modelData.active)
                                network.disabled = false;
                        }

                        target: network.modelData
                    }

                    Connections {
                        function onNetworkSelected(ap: Nmcli.AccessPoint): void {
                            if (ap !== network.modelData)
                                network.disabled = false;
                        }

                        target: root
                    }

                    SequentialAnimation {
                        id: rightCompAnim

                        running: false

                        Anim {
                            target: rightLoader
                            property: "opacity"
                            to: 0
                            type: Anim.FastEffects
                        }
                        ScriptAction {
                            script: rightLoader.sourceComponent = network.rightComp
                        }
                        Anim {
                            target: rightLoader
                            property: "opacity"
                            to: 1
                            type: Anim.DefaultEffects
                        }
                    }

                    RowLayout {
                        id: networkLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: Icons.getNetworkIcon(network.modelData.strength)
                            color: network.modelData.active ? Colours.palette.m3primary : Colours.tPalette.m3onSurfaceVariant
                            font: Tokens.font.icon.medium
                            opacity: network.textOpacity
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            opacity: network.textOpacity

                            StyledText {
                                Layout.fillWidth: true
                                text: network.modelData.ssid
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Security: %1").arg(network.modelData.security)
                                color: Colours.tPalette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        Loader {
                            id: rightLoader

                            asynchronous: true
                            sourceComponent: iconComp

                            Component {
                                id: iconComp

                                MaterialIcon {
                                    text: network.modelData.active ? "settings" : "lock"
                                    color: network.modelData.active ? Colours.palette.m3primary : Colours.tPalette.m3onSurfaceVariant
                                    font: Tokens.font.icon.medium
                                    opacity: network.textOpacity
                                }
                            }

                            Component {
                                id: loadingComp

                                LoadingIndicator {
                                    implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                                }
                            }
                        }
                    }
                }
            }

            StyledProgressBar {
                id: scanningIndicator

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                implicitHeight: Nmcli.scanning ? Tokens.rounding.extraSmall : 0
                indeterminate: true

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            bottomLeftRadius: Tokens.rounding.extraLarge
            bottomRightRadius: Tokens.rounding.extraLarge
            radius: Tokens.rounding.extraSmall

            implicitHeight: addNetworkLayout.implicitHeight + addNetworkLayout.anchors.margins * 2
            color: Colours.tPalette.m3surfaceContainer

            StateLayer {}

            RowLayout {
                id: addNetworkLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "add"
                    color: Colours.tPalette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Add network")
                    color: Colours.tPalette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
