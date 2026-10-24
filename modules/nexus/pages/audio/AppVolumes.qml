pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("App routing & volumes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.tr("Adjust the volume of individual apps and route them to specific output devices.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: streamList

            first: true
            last: true
            showList: true
            placeholderIcon: "music_off"
            placeholderText: Tr.tr("No apps playing audio")
            color: list.count === 0 ? Colours.tPalette.m3surfaceContainer : "transparent"
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...Audio.streams]
            }

            delegate: ConnectedRect {
                id: streamCard

                required property PwNode modelData
                required property int index

                property bool showRouting: false

                readonly property real streamVol: streamCard.modelData?.audio?.volume ?? 0
                readonly property bool streamMuted: streamCard.modelData?.audio?.muted ?? false
                readonly property string streamIcon: Audio.getStreamIcon(streamCard.modelData)
                readonly property string streamName: Audio.getStreamName(streamCard.modelData)
                readonly property int targetSinkId: Audio.getStreamTargetId(streamCard.modelData)
                readonly property PwNode targetSinkNode: Audio.sinks.find(s => s && s.id === streamCard.targetSinkId) ?? null
                readonly property string targetSinkName: targetSinkNode ? (targetSinkNode.description || targetSinkNode.name) : Tr.tr("System Default")

                anchors.left: streamList.list.contentItem.left
                anchors.right: streamList.list.contentItem.right
                first: index === 0
                last: index === streamList.list.count - 1
                implicitHeight: cardCol.implicitHeight + cardCol.anchors.margins * 2

                ColumnLayout {
                    id: cardCol

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    // Header row: Icon, App Name, Output Target Picker, Mute Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        CachingIconImage {
                            source: streamCard.streamIcon
                            implicitSize: Tokens.font.icon.medium.pointSize
                            visible: !!streamCard.streamIcon
                        }

                        MaterialIcon {
                            visible: !streamCard.streamIcon
                            text: "music_note"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: streamCard.streamName
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        // Target Sink Picker Button
                        IconTextButton {
                            id: routeBtn

                            type: ButtonBase.Tonal
                            icon: streamCard.targetSinkNode ? (streamCard.targetSinkNode.properties?.["device.api"] === "bluez5" ? "headphones" : (streamCard.targetSinkNode.name === Audio.combinedModuleName ? "cable" : "speaker")) : "alt_route"
                            text: streamCard.targetSinkName
                            onClicked: streamCard.showRouting = !streamCard.showRouting
                        }

                        // Mute button
                        IconButton {
                            icon: Icons.getVolumeIcon(streamCard.streamVol, streamCard.streamMuted)
                            type: IconButton.Text
                            inactiveOnColour: streamCard.streamMuted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            onClicked: Audio.setStreamMuted(streamCard.modelData, !streamCard.streamMuted)
                        }
                    }

                    // Volume slider row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: streamCard.streamMuted ? Tr.tr("Muted") : Strings.percentOne(streamCard.streamVol)
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            Layout.preferredWidth: 42
                        }

                        CustomMouseArea {
                            function onWheel(event: WheelEvent): void {
                                const step = GlobalConfig.services.audioIncrement;
                                if (event.angleDelta.y > 0)
                                    Audio.setStreamVolume(streamCard.modelData, Math.min(1, streamCard.streamVol + step));
                                else if (event.angleDelta.y < 0)
                                    Audio.setStreamVolume(streamCard.modelData, Math.max(0, streamCard.streamVol - step));
                            }

                            Layout.fillWidth: true
                            implicitHeight: Tokens.padding.medium * 2

                            StyledSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: parent.implicitHeight

                                radius: Tokens.rounding.small
                                value: streamCard.streamVol
                                enabled: !streamCard.streamMuted
                                onInteraction: v => Audio.setStreamVolume(streamCard.modelData, v)
                            }
                        }
                    }

                    // Expandable routing device selector
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.extraSmall
                        visible: streamCard.showRouting
                        spacing: Tokens.spacing.extraSmall / 2

                        StyledText {
                            text: Tr.tr("Route output to:")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        Repeater {
                            model: [
                                { id: -1, name: Tr.tr("System Default"), isBt: false, isComb: false, node: null },
                                ...Audio.sinks.filter(s => s).map(s => ({
                                    id: s.id,
                                    name: s.description || s.name,
                                    isBt: s.properties?.["device.api"] === "bluez5",
                                    isComb: s.name === Audio.combinedModuleName,
                                    node: s
                                }))
                            ]

                            delegate: StyledRect {
                                id: sinkOption

                                required property var modelData
                                readonly property bool isSelected: (modelData.id === -1 && streamCard.targetSinkId === -1) || (streamCard.targetSinkId === modelData.id)

                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: Tokens.rounding.small
                                color: isSelected ? Qt.alpha(Colours.palette.m3primaryContainer, 0.6) : (optLayer.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

                                StateLayer {
                                    id: optLayer
                                    anchors.fill: parent
                                    radius: parent.radius
                                    onClicked: {
                                        Audio.setStreamTarget(streamCard.modelData, sinkOption.modelData.node);
                                        streamCard.showRouting = false;
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.small

                                    MaterialIcon {
                                        text: sinkOption.modelData.isBt ? "headphones" : (sinkOption.modelData.isComb ? "cable" : (sinkOption.modelData.id === -1 ? "check_circle" : "speaker"))
                                        color: sinkOption.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: sinkOption.modelData.name
                                        font: Tokens.font.body.small
                                        color: sinkOption.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                    }

                                    MaterialIcon {
                                        visible: sinkOption.isSelected
                                        text: "check"
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
