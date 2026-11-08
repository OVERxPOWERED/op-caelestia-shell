pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property real parentWidth: 1920
    property real parentHeight: 1080

    // Animation physics state
    property real animY: -85
    property real animScaleX: 0.8
    property real animScaleY: 0.8
    property real animOpacity: 0.0

    readonly property bool isListening: VoiceTyping.isListening
    readonly property bool isPaused: VoiceTyping.isPaused
    readonly property bool isTranscribing: VoiceTyping.isTranscribing
    readonly property bool isDone: VoiceTyping.isDone
    readonly property bool isPressed: dragArea.pressed
    readonly property bool isDragging: dragArea.pressed || dragArea.drag.active

    // Target width for each state (explicit deterministic geometry)
    readonly property real targetWidth: {
        if (!VoiceTyping.active)
            return 56;
        if (isPaused)
            return 256;
        if (isListening)
            return VoiceTyping.liveTranscript
                ? Math.min(360, Math.max(260, 100 + statusLabel.implicitWidth))
                : 256;
        if (isTranscribing)
            return VoiceTyping.liveTranscript
                ? Math.min(360, Math.max(260, 100 + statusLabel.implicitWidth))
                : 216;
        if (isDone)
            return Math.min(360, Math.max(248, 100 + statusLabel.implicitWidth));
        return 256;
    }

    // Dynamic color theming
    readonly property color accentColor: isListening
        ? Colours.palette.m3primary
        : isPaused
            ? Colours.palette.m3tertiary
            : isDone
                ? Colours.palette.m3secondary
                : Colours.palette.m3primary

    readonly property color onAccentColor: isListening
        ? Colours.palette.m3onPrimary
        : isPaused
            ? Colours.palette.m3onTertiary
            : isDone
                ? Colours.palette.m3onSecondary
                : Colours.palette.m3onPrimary

    // Container geometry
    property real currentPillWidth: VoiceTyping.active ? root.targetWidth : 56
    property real currentPillHeight: 48
    property real heightBounce: 0

    function updateFromSavedPosition(): void {
        if (VoiceTyping.customPosition && VoiceTyping.pillX >= 0) {
            root.x = Math.max(8, Math.min(parentWidth - root.width - 8, VoiceTyping.pillX));
        } else {
            root.x = Math.max(8, (parentWidth - root.width) / 2);
        }

        if (VoiceTyping.customPosition && VoiceTyping.pillY >= 0) {
            root.y = Math.max(8, Math.min(parentHeight - root.height - 8, VoiceTyping.pillY));
        } else {
            root.y = 16;
        }
    }

    implicitWidth: currentPillWidth
    implicitHeight: currentPillHeight + heightBounce
    width: implicitWidth
    height: implicitHeight

    scale: 1.0
    opacity: animOpacity

    onParentWidthChanged: {
        if (!dragArea.drag.active)
            root.updateFromSavedPosition();
    }

    onTargetWidthChanged: {
        if (VoiceTyping.active)
            squashBounceAnim.restart();
    }

    transform: Scale {
        origin.x: root.implicitWidth / 2
        origin.y: 0
        xScale: root.animScaleX
        yScale: root.animScaleY
    }

    states: [
        State {
            name: "visible"
            when: VoiceTyping.active

            PropertyChanges {
                target: root
                animY: 0
                animScaleX: 1.0
                animScaleY: 1.0
                animOpacity: 1.0
            }
        },
        State {
            name: "hidden"
            when: !VoiceTyping.active

            PropertyChanges {
                target: root
                animY: -85
                animScaleX: 0.8
                animScaleY: 0.8
                animOpacity: 0.0
            }
        }
    ]

    transitions: [
        Transition {
            from: "hidden"
            to: "visible"

            ParallelAnimation {
                SpringAnimation {
                    target: root
                    property: "animY"
                    spring: 3.6
                    damping: 0.30
                    mass: 0.95
                    epsilon: 0.2
                }

                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: root
                            property: "animScaleX"
                            to: 0.90
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: root
                            property: "animScaleY"
                            to: 1.12
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: root
                            property: "animScaleX"
                            to: 1.04
                            duration: 160
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: root
                            property: "animScaleY"
                            to: 0.96
                            duration: 160
                            easing.type: Easing.InOutQuad
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: root
                            property: "animScaleX"
                            to: 1.0
                            duration: 180
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                        NumberAnimation {
                            target: root
                            property: "animScaleY"
                            to: 1.0
                            duration: 180
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                }

                NumberAnimation {
                    target: root
                    property: "animOpacity"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "visible"
            to: "hidden"

            ParallelAnimation {
                SpringAnimation {
                    target: root
                    property: "animY"
                    spring: 4.8
                    damping: 0.45
                    mass: 0.85
                    epsilon: 0.2
                }
                NumberAnimation {
                    target: root
                    property: "animScaleX"
                    to: 0.8
                    duration: 220
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: root
                    property: "animScaleY"
                    to: 0.8
                    duration: 220
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: root
                    property: "animOpacity"
                    duration: 160
                    easing.type: Easing.InQuad
                }
            }
        }
    ]

    Component.onCompleted: updateFromSavedPosition()

    // Spring physics for horizontal width morphing
    Behavior on currentPillWidth {
        SpringAnimation {
            spring: 4.2
            damping: 0.28
            epsilon: 0.15
            mass: 1.0
        }
    }

    Connections {
        function onPillPositionChanged(): void {
            if (!dragArea.drag.active) {
                root.updateFromSavedPosition();
            }
        }

        target: VoiceTyping
    }

    // Secondary vertical squash-and-stretch bounce on state change
    SequentialAnimation {
        id: squashBounceAnim

        NumberAnimation {
            target: root
            property: "heightBounce"
            to: 4.0
            duration: 120
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "heightBounce"
            to: -2.0
            duration: 140
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "heightBounce"
            to: 0
            duration: 160
            easing.type: Easing.OutBounce
        }
    }

    // Main capsule container
    StyledRect {
        id: pillBg

        y: root.animY
        width: root.width
        height: root.height
        radius: height / 2
        clip: true

        color: Colours.tPalette.m3surfaceContainerHigh
        border.color: root.isListening
            ? Qt.alpha(root.accentColor, 0.40)
            : root.isPaused
                ? Qt.alpha(root.accentColor, 0.35)
                : Qt.rgba(1.0, 1.0, 1.0, 0.16)
        border.width: 1

        Behavior on border.color {
            CAnim {}
        }

        // MouseArea for dragging and click toggle
        MouseArea {
            id: dragArea

            property real startMouseX: 0
            property real startMouseY: 0
            property bool isDragging: false

            anchors.fill: parent
            preventStealing: true
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.threshold: 2
            drag.minimumX: 8
            drag.maximumX: Math.max(8, root.parentWidth - root.width - 8)
            drag.minimumY: 8
            drag.maximumY: Math.max(8, root.parentHeight - root.height - 8)

            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor

            onPressed: mouse => {
                startMouseX = mouse.x;
                startMouseY = mouse.y;
                isDragging = false;
            }

            onPositionChanged: mouse => {
                const dx = Math.abs(mouse.x - startMouseX);
                const dy = Math.abs(mouse.y - startMouseY);
                if (dx > 4 || dy > 4) {
                    isDragging = true;
                }
            }

            onReleased: mouse => {
                if (isDragging) {
                    VoiceTyping.savePosition(root.x, root.y);
                } else {
                    if (mouse.button === Qt.RightButton) {
                        VoiceTyping.cancel();
                    } else {
                        VoiceTyping.togglePause();
                    }
                }
                isDragging = false;
            }
        }

        // Content viewport with fixed anchors (no layout jitter!)
        Item {
            id: contentArea

            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            // 1. Left Badge (Microphone / Status Icon)
            Item {
                id: iconBox

                width: 34
                height: 34
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                // Ambient pulsing glow
                Rectangle {
                    id: pulseGlow

                    anchors.centerIn: parent
                    width: parent.width + (root.isListening ? 8 : 0)
                    height: parent.height + (root.isListening ? 8 : 0)
                    radius: width / 2
                    color: Qt.alpha(root.accentColor, root.isListening ? 0.20 : 0.0)

                    Behavior on width {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    Behavior on height {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    Behavior on color {
                        CAnim {}
                    }

                    SequentialAnimation on opacity {
                        running: root.isListening
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 0.35
                            to: 0.95
                            duration: 650
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            from: 0.95
                            to: 0.35
                            duration: 650
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                // Frosted Circular Glass Badge
                Rectangle {
                    id: badgeCircle

                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.accentColor, root.isListening ? 0.22 : 0.14)
                    border.color: Qt.alpha(root.accentColor, root.isListening ? 0.45 : 0.25)
                    border.width: 1

                    Behavior on color {
                        CAnim {}
                    }

                    Behavior on border.color {
                        CAnim {}
                    }

                    MaterialIcon {
                        id: micIcon

                        anchors.centerIn: parent
                        color: root.accentColor
                        fontStyle: Tokens.font.icon.small

                        text: {
                            if (root.isPaused)
                                return "pause";
                            if (root.isTranscribing)
                                return "hourglass_top";
                            if (root.isDone)
                                return "check";
                            return "mic";
                        }
                    }
                }
            }

            // 2. Audio Waveform Bars (Liquid audio feedback)
            Row {
                id: waveRow

                spacing: 3
                anchors.left: iconBox.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.isDone ? 0.0 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Repeater {
                    model: 4

                    Rectangle {
                        id: waveBar

                        required property int index

                        readonly property real barLevel: (VoiceTyping.barLevels && VoiceTyping.barLevels.length > index)
                            ? VoiceTyping.barLevels[index]
                            : 0.0

                        readonly property real dynamicHeight: Math.min(26.0, Math.max(4.0, 4.0 + barLevel * 22.0))

                        width: 3.5
                        radius: 1.75
                        color: root.accentColor

                        height: {
                            if (root.isListening)
                                return dynamicHeight;
                            if (root.isPaused)
                                return (index === 1 || index === 2) ? 10.0 : 4.0;
                            return 4.0;
                        }

                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on height {
                            NumberAnimation {
                                duration: root.isPaused ? 200 : 35
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }
            }

            // 3. Status Text / Transcribed Preview
            Item {
                id: textViewport

                anchors.left: waveRow.right
                anchors.leftMargin: 10
                anchors.right: resumeBadge.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                clip: true

                StyledText {
                    id: statusLabel

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: VoiceTyping.statusText
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurface
                    elide: VoiceTyping.liveTranscript ? Text.ElideLeft : Text.ElideRight
                    width: parent.width

                    onTextChanged: {
                        if (opacityAnim.running)
                            opacityAnim.stop();
                        opacityAnim.restart();
                    }

                    SequentialAnimation on opacity {
                        id: opacityAnim

                        running: false

                        NumberAnimation {
                            to: 0.3
                            duration: 40
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 70
                            easing.type: Easing.InQuad
                        }
                    }
                }
            }

            // 4. Resume Badge (Smooth elastic bloom when paused)
            Rectangle {
                id: resumeBadge

                anchors.right: closeBtn.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter

                width: root.isPaused ? 26 : 0
                height: 24
                radius: 12
                clip: true

                opacity: root.isPaused ? 1.0 : 0.0
                scale: root.isPaused ? 1.0 : 0.6

                color: Qt.alpha(Colours.palette.m3tertiary, 0.20)
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.22)
                border.width: 1

                Behavior on width {
                    SpringAnimation {
                        spring: 4.5
                        damping: 0.32
                        epsilon: 0.1
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    SpringAnimation {
                        spring: 4.5
                        damping: 0.32
                        epsilon: 0.1
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "play_arrow"
                    color: Colours.palette.m3tertiary
                    fontStyle: Tokens.font.icon.small
                }
            }

            // 5. Close / Cancel Button (Far right)
            IconButton {
                id: closeBtn

                icon: "close"
                type: IconButton.Text
                opacity: 0.75
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: VoiceTyping.cancel()

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }
        }
    }
}
