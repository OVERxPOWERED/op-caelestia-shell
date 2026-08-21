pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts

    readonly property list<PwNode> sortedStreams: [...Audio.streams].sort((a, b) => (Audio.getStreamName(a) || "").localeCompare(Audio.getStreamName(b) || ""))
    property int selectedStreamId: -1
    readonly property PwNode selectedStream: {
        if (sortedStreams.length === 0)
            return null;
        const found = sortedStreams.find(s => s.id === root.selectedStreamId);
        return found ?? sortedStreams[0];
    }

    readonly property int maxExpandedApps: 2
    readonly property bool useCompactAppSelector: sortedStreams.length > maxExpandedApps

    implicitWidth: Math.max(280, layout.implicitWidth + Tokens.padding.medium * 2)
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        StyledText {
            text: qsTr("Output device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sinks

            StyledRadioButton {
                id: control

                required property PwNode modelData

                ButtonGroup.group: sinks
                checked: Audio.sink?.id === modelData.id
                onClicked: Audio.setAudioSink(modelData)
                text: modelData.description
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: qsTr("Input device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sources

            StyledRadioButton {
                required property PwNode modelData

                ButtonGroup.group: sources
                checked: Audio.source?.id === modelData.id
                onClicked: Audio.setAudioSource(modelData)
                text: modelData.description
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.small

            IconButton {
                icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                type: IconButton.Text
                inactiveOnColour: Audio.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                onClicked: Audio.setStreamMuted(Audio.sink, !Audio.muted)
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: 18

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 12

                value: Audio.volume
                onInteraction: value => Audio.setVolume(value)
            }
        }

        // Applications Header with active stream counter badge
        RowLayout {
            Layout.topMargin: Tokens.spacing.medium
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Applications")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            Item {
                Layout.fillWidth: true
            }

            StyledRect {
                visible: root.sortedStreams.length > 0
                implicitHeight: 20
                implicitWidth: countText.implicitWidth + Tokens.padding.small * 2
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StyledText {
                    id: countText

                    anchors.centerIn: parent
                    text: qsTr("%1 active").arg(root.sortedStreams.length)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Empty state: No audio streams active
        RowLayout {
            Layout.fillWidth: true
            visible: root.sortedStreams.length === 0
            spacing: Tokens.spacing.small
            opacity: 0.7

            MaterialIcon {
                text: "music_off"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("No apps playing audio")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }

        // Direct List Mode: Used when <= maxExpandedApps are active
        Repeater {
            model: (!root.useCompactAppSelector && root.sortedStreams.length > 0) ? root.sortedStreams : []

            ColumnLayout {
                id: streamControl

                required property PwNode modelData
                readonly property real streamVol: Audio.getStreamVolume(modelData)
                readonly property bool streamMuted: Audio.getStreamMuted(modelData)
                readonly property string streamIcon: Audio.getStreamIcon(modelData)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconButton {
                        icon: Icons.getVolumeIcon(streamControl.streamVol, streamControl.streamMuted)
                        type: IconButton.Text
                        inactiveOnColour: streamControl.streamMuted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        onClicked: Audio.setStreamMuted(streamControl.modelData, !streamControl.streamMuted)
                    }

                    IconImage {
                        visible: streamControl.streamIcon !== ""
                        asynchronous: true
                        implicitSize: 16
                        source: streamControl.streamIcon
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        Layout.preferredWidth: 0
                        Layout.fillWidth: true
                        text: Audio.getStreamName(streamControl.modelData)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: streamControl.streamMuted ? qsTr("Muted") : `${Math.round(streamControl.streamVol * 100)}%`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }

                CustomMouseArea {
                    Layout.fillWidth: true
                    implicitHeight: 16

                    onWheel: event => {
                        const step = GlobalConfig.services.audioIncrement;
                        const curVol = streamControl.streamVol;
                        if (event.angleDelta.y > 0)
                            Audio.setStreamVolume(streamControl.modelData, Math.min(1, curVol + step));
                        else if (event.angleDelta.y < 0)
                            Audio.setStreamVolume(streamControl.modelData, Math.max(0, curVol - step));
                    }

                    StyledSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitHeight: 10

                        radius: Tokens.rounding.small
                        value: streamControl.streamVol
                        enabled: !streamControl.streamMuted
                        onInteraction: v => Audio.setStreamVolume(streamControl.modelData, v)
                    }
                }
            }
        }

        // Compact Carousel / Pill Chips Mode: Used when > maxExpandedApps are active
        ColumnLayout {
            id: compactStreamControl

            visible: root.useCompactAppSelector
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: Tokens.spacing.small

            readonly property PwNode currentStream: root.selectedStream
            readonly property real streamVol: currentStream ? Audio.getStreamVolume(currentStream) : 0
            readonly property bool streamMuted: currentStream ? Audio.getStreamMuted(currentStream) : false
            readonly property string currentIcon: currentStream ? Audio.getStreamIcon(currentStream) : ""

            function scrollToSelected(): void {
                for (let i = 0; i < chipRepeater.count; i++) {
                    const item = chipRepeater.itemAt(i);
                    if (item && item.isSelected) {
                        chipFlickable.scrollTo(item);
                        break;
                    }
                }
            }

            HorizontalFadeFlickable {
                id: chipFlickable

                function scrollTo(item: Item): void {
                    if (!item)
                        return;
                    const targetX = Math.max(0, Math.min(chipFlickable.contentWidth - chipFlickable.width, item.x + item.width / 2 - chipFlickable.width / 2));
                    scrollAnim.stop();
                    scrollAnim.to = targetX;
                    scrollAnim.start();
                }

                Anim {
                    id: scrollAnim

                    target: chipFlickable
                    property: "contentX"
                    type: Anim.DefaultSpatial
                }

                Layout.fillWidth: true
                implicitHeight: 32
                contentWidth: chipRow.implicitWidth
                contentHeight: 32
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    orientation: Qt.Horizontal
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        scrollAnim.stop();
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        chipFlickable.contentX = Math.max(0, Math.min(chipFlickable.contentWidth - chipFlickable.width, chipFlickable.contentX - delta));
                    }
                }

                Row {
                    id: chipRow

                    spacing: Tokens.spacing.extraSmall
                    height: parent.height

                    Repeater {
                        id: chipRepeater

                        model: root.useCompactAppSelector ? root.sortedStreams : []

                        StyledRect {
                            id: chip

                            required property PwNode modelData
                            readonly property bool isSelected: root.selectedStream?.id === modelData.id
                            readonly property bool isMuted: Audio.getStreamMuted(modelData)
                            readonly property string streamName: Audio.getStreamName(modelData)
                            readonly property string appIcon: Audio.getStreamIcon(modelData)

                            implicitHeight: 28
                            implicitWidth: Math.min(145, chipInnerRow.implicitWidth + Tokens.padding.small * 2)
                            radius: Tokens.rounding.full

                            scale: stateLayer.pressed ? 0.94 : isSelected ? 1.04 : (stateLayer.containsMouse ? 1.02 : 1.0)
                            opacity: isSelected ? 1.0 : (stateLayer.containsMouse ? 0.9 : 0.75)

                            color: isSelected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

                            Behavior on color {
                                CAnim {}
                            }

                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            StateLayer {
                                id: stateLayer

                                color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                onClicked: {
                                    root.selectedStreamId = chip.modelData.id;
                                    chipFlickable.scrollTo(chip);
                                }
                            }

                            RowLayout {
                                id: chipInnerRow

                                anchors.centerIn: parent
                                spacing: Tokens.spacing.extraSmall
                                width: Math.min(parent.width - Tokens.padding.small, implicitWidth)

                                IconImage {
                                    visible: chip.appIcon !== ""
                                    asynchronous: true
                                    implicitSize: 14
                                    source: chip.appIcon
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                MaterialIcon {
                                    visible: chip.appIcon === ""
                                    text: "music_note"
                                    fontStyle: Tokens.font.icon.small
                                    color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 90
                                    text: chip.streamName
                                    color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MaterialIcon {
                                    visible: chip.isMuted
                                    text: "volume_off"
                                    fontStyle: Tokens.font.icon.small
                                    color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3error
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconButton {
                    icon: Icons.getVolumeIcon(compactStreamControl.streamVol, compactStreamControl.streamMuted)
                    type: IconButton.Text
                    inactiveOnColour: compactStreamControl.streamMuted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    onClicked: {
                        if (compactStreamControl.currentStream)
                            Audio.setStreamMuted(compactStreamControl.currentStream, !compactStreamControl.streamMuted);
                    }
                }

                IconImage {
                    visible: compactStreamControl.currentIcon !== ""
                    asynchronous: true
                    implicitSize: 16
                    source: compactStreamControl.currentIcon
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    text: compactStreamControl.currentStream ? Audio.getStreamName(compactStreamControl.currentStream) : ""
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: compactStreamControl.streamMuted ? qsTr("Muted") : `${Math.round(compactStreamControl.streamVol * 100)}%`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: 16

                onWheel: event => {
                    if (!compactStreamControl.currentStream)
                        return;
                    const step = GlobalConfig.services.audioIncrement;
                    const curVol = compactStreamControl.streamVol;
                    if (event.angleDelta.y > 0)
                        Audio.setStreamVolume(compactStreamControl.currentStream, Math.min(1, curVol + step));
                    else if (event.angleDelta.y < 0)
                        Audio.setStreamVolume(compactStreamControl.currentStream, Math.max(0, curVol - step));
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 10

                    radius: Tokens.rounding.small
                    value: compactStreamControl.streamVol
                    enabled: compactStreamControl.currentStream && !compactStreamControl.streamMuted
                    onInteraction: v => {
                        if (compactStreamControl.currentStream)
                            Audio.setStreamVolume(compactStreamControl.currentStream, v);
                    }
                }
            }
        }

        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: qsTr("Open settings")
            icon: "settings"

            onClicked: root.popouts.detachRequested("audio")
        }
    }
}


