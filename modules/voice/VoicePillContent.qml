pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    property real parentWidth: 1920
    property real parentHeight: 1080

    readonly property bool isListening: VoiceTyping.isListening
    readonly property bool isPaused: VoiceTyping.isPaused
    readonly property bool isTranscribing: VoiceTyping.isTranscribing
    readonly property bool isDone: VoiceTyping.isDone
    readonly property bool isPressed: dragArea.pressed
    readonly property bool isDragging: dragArea.pressed || dragArea.drag.active

    readonly property string theme: VoiceTyping.theme
    readonly property bool isWaveMode: theme === "wave"
    readonly property bool isCompactMode: theme === "compact"
    readonly property bool isClassicMode: theme === "classic" || (!isWaveMode && !isCompactMode)

    readonly property string transcriptText: VoiceTyping.transcriptionPreview ? VoiceTyping.previewTranscript : ""
    readonly property bool hasTranscript: transcriptText.length > 0 && !isDone
    readonly property bool showCloseButton: !isDone && !isWaveMode && (hoverHandler.hovered || dragArea.containsMouse)

    // System-consistent surface & accent colors
    readonly property color surfaceColor: Colours.transparency.enabled
        ? Qt.alpha(Colours.palette.m3surface, Math.min(Colours.transparency.base, 0.78))
        : Colours.palette.m3surface

    readonly property color accentColor: isDone
        ? Colours.palette.m3success
        : isPaused
            ? Colours.palette.m3tertiary
            : Colours.palette.m3primary

    readonly property bool isBottomAnchored: {
        if (VoiceTyping.customPosition && VoiceTyping.pillY >= 0)
            return (VoiceTyping.pillY + targetHeight / 2) > (parentHeight / 2);
        return VoiceTyping.positionPreset.startsWith("bottom");
    }

    readonly property real hiddenSlideOffset: isBottomAnchored ? 56 : -56

    // Animation state
    property real animY: hiddenSlideOffset
    property real animScaleX: 0.88
    property real animScaleY: 0.88
    property real animOpacity: 0.0
    property real heightBounce: 0

    // Target geometry per theme & state
    readonly property real targetWidth: {
        if (!VoiceTyping.active)
            return isWaveMode ? 420 : 180;

        if (isWaveMode)
            return Math.min(480, Math.max(320, parentWidth - 48));

        if (isDone) {
            const doneW = doneTextMetrics.implicitWidth + 84;
            return Math.min(360, Math.max(196, doneW));
        }

        if (isCompactMode) {
            const textW = Math.max(compactLabelMetrics.implicitWidth, 72);
            const waveW = VoiceTyping.liveWaveform ? 44 : 0;
            const closeW = showCloseButton ? 28 : 0;
            return Math.min(420, Math.max(188, 54 + textW + waveW + closeW));
        }

        // Classic (two-line)
        const line1W = classicStatusMetrics.implicitWidth + 16;
        const line2W = hasTranscript ? classicTranscriptMetrics.implicitWidth : 0;
        const textBlockW = Math.max(82, Math.min(250, Math.max(line1W, line2W)));
        const badgeW = 46;
        const waveW = VoiceTyping.liveWaveform ? 74 : 4;
        const closeW = showCloseButton ? 28 : 0;
        return Math.min(440, Math.max(216, 22 + badgeW + textBlockW + waveW + closeW));
    }

    readonly property real targetHeight: {
        if (isWaveMode) {
            if (isDone)
                return 54;
            return hasTranscript ? Math.max(84, 54 + waveTranscriptText.implicitHeight + 6) : 54;
        }
        if (isDone)
            return Math.max(46, doneTextMetrics.implicitHeight + 22);
        if (isCompactMode)
            return Math.max(40, compactLabelMetrics.implicitHeight + 18);
        // Classic (two-line)
        const linesH = classicStatusMetrics.implicitHeight + (hasTranscript ? classicTranscriptMetrics.implicitHeight + 2 : 0);
        return Math.max(50, linesH + 18);
    }

    property real currentWidth: targetWidth
    property real currentHeight: targetHeight

    Behavior on currentWidth {
        enabled: VoiceTyping.enableAnimations
        SpringAnimation {
            spring: 4.5 * VoiceTyping.speedFactor
            damping: 0.34
            epsilon: 0.15
            mass: 0.9
        }
    }

    Behavior on currentHeight {
        enabled: VoiceTyping.enableAnimations
        SpringAnimation {
            spring: 4.5 * VoiceTyping.speedFactor
            damping: 0.36
            epsilon: 0.15
            mass: 0.9
        }
    }

    function updateFromSavedPosition(): void {
        const edgeX = 20;
        const topY = 16;
        const bottomY = 26;

        if (VoiceTyping.customPosition && VoiceTyping.pillX >= 0 && VoiceTyping.pillY >= 0) {
            root.x = Math.max(8, Math.min(parentWidth - root.width - 8, VoiceTyping.pillX));
            root.y = Math.max(8, Math.min(parentHeight - root.height - 8, VoiceTyping.pillY));
            return;
        }

        const preset = VoiceTyping.positionPreset || "top-center";
        if (preset.endsWith("left"))
            root.x = edgeX;
        else if (preset.endsWith("right"))
            root.x = Math.max(8, parentWidth - root.width - edgeX);
        else
            root.x = Math.max(8, (parentWidth - root.width) / 2);

        if (preset.startsWith("bottom"))
            root.y = Math.max(8, parentHeight - root.height - bottomY);
        else
            root.y = topY;
    }

    implicitWidth: currentWidth
    implicitHeight: currentHeight + heightBounce
    width: implicitWidth
    height: implicitHeight
    opacity: animOpacity

    onParentWidthChanged: {
        if (!dragArea.drag.active)
            updateFromSavedPosition();
    }

    onParentHeightChanged: {
        if (!dragArea.drag.active)
            updateFromSavedPosition();
    }

    onWidthChanged: {
        if (!VoiceTyping.customPosition && !dragArea.drag.active)
            updateFromSavedPosition();
    }

    onHeightChanged: {
        if (!VoiceTyping.customPosition && !dragArea.drag.active)
            updateFromSavedPosition();
    }

    onTargetWidthChanged: {
        if (VoiceTyping.active && VoiceTyping.enableAnimations && !isWaveMode)
            squashBounceAnim.restart();
    }

    Component.onCompleted: updateFromSavedPosition()

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.animScaleX * VoiceTyping.scaleFactor
        yScale: root.animScaleY * VoiceTyping.scaleFactor
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
                animY: root.hiddenSlideOffset
                animScaleX: 0.88
                animScaleY: 0.88
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
                    spring: (VoiceTyping.enableAnimations ? 4.2 : 40.0) * VoiceTyping.speedFactor
                    damping: VoiceTyping.enableAnimations ? 0.34 : 1.0
                    mass: 0.9
                    epsilon: 0.2
                }
                SpringAnimation {
                    target: root
                    property: "animScaleX"
                    spring: (VoiceTyping.enableAnimations ? 4.6 : 40.0) * VoiceTyping.speedFactor
                    damping: VoiceTyping.enableAnimations ? 0.36 : 1.0
                    mass: 0.85
                    epsilon: 0.002
                }
                SpringAnimation {
                    target: root
                    property: "animScaleY"
                    spring: (VoiceTyping.enableAnimations ? 4.6 : 40.0) * VoiceTyping.speedFactor
                    damping: VoiceTyping.enableAnimations ? 0.36 : 1.0
                    mass: 0.85
                    epsilon: 0.002
                }
                NumberAnimation {
                    target: root
                    property: "animOpacity"
                    duration: VoiceTyping.enableAnimations ? Math.max(80, Math.round(170 / VoiceTyping.speedFactor)) : 0
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "visible"
            to: "hidden"

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "animY"
                    duration: VoiceTyping.enableAnimations ? Math.max(90, Math.round(190 / VoiceTyping.speedFactor)) : 0
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: root
                    property: "animScaleX"
                    duration: VoiceTyping.enableAnimations ? Math.max(90, Math.round(180 / VoiceTyping.speedFactor)) : 0
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: root
                    property: "animScaleY"
                    duration: VoiceTyping.enableAnimations ? Math.max(90, Math.round(180 / VoiceTyping.speedFactor)) : 0
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: root
                    property: "animOpacity"
                    duration: VoiceTyping.enableAnimations ? Math.max(80, Math.round(150 / VoiceTyping.speedFactor)) : 0
                    easing.type: Easing.InQuad
                }
            }
        }
    ]

    Connections {
        function onPillPositionChanged(): void {
            if (!dragArea.drag.active)
                root.updateFromSavedPosition();
        }

        target: VoiceTyping
    }

    // Subtle squash-and-stretch settle on pill morphs
    SequentialAnimation {
        id: squashBounceAnim

        NumberAnimation {
            target: root
            property: "heightBounce"
            to: 2.5
            duration: Math.max(60, Math.round(100 / VoiceTyping.speedFactor))
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "heightBounce"
            to: 0
            duration: Math.max(80, Math.round(150 / VoiceTyping.speedFactor))
            easing.type: Easing.OutBack
        }
    }

    // Hidden text metrics for deterministic sizing across all user font configurations
    StyledText {
        id: classicStatusMetrics
        visible: false
        text: VoiceTyping.statusText
        font: Tokens.font.label.medium
    }

    StyledText {
        id: classicTranscriptMetrics
        visible: false
        text: root.transcriptText
        font: Tokens.font.label.small
    }

    StyledText {
        id: compactLabelMetrics
        visible: false
        text: root.hasTranscript ? root.transcriptText : VoiceTyping.statusText
        font: Tokens.font.label.medium
    }

    StyledText {
        id: doneTextMetrics
        visible: false
        text: VoiceTyping.statusText
        font: Tokens.font.label.medium
    }

    // Interactive container positioned at animY
    Item {
        id: bodyContainer

        y: root.animY
        width: root.width
        height: root.height

        HoverHandler {
            id: hoverHandler
        }

        // Drag / click-to-pause / right-click-to-cancel area
        MouseArea {
            id: dragArea

            property real startMouseX: 0
            property real startMouseY: 0
            property bool isDragging: false

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
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
                if (Math.abs(mouse.x - startMouseX) > 4 || Math.abs(mouse.y - startMouseY) > 4)
                    isDragging = true;
            }

            onReleased: mouse => {
                if (isDragging) {
                    VoiceTyping.savePosition(root.x, root.y);
                } else if (mouse.button === Qt.RightButton) {
                    VoiceTyping.cancel();
                } else if (!root.isDone) {
                    VoiceTyping.togglePause();
                }
                isDragging = false;
            }
        }

        // =========================================================================
        // 1. PILL CONTAINER (Classic & Compact themes)
        // =========================================================================
        StyledRect {
            id: pillBg

            anchors.fill: parent
            visible: !root.isWaveMode
            radius: height / 2
            clip: true
            antialiasing: true
            color: root.surfaceColor

            GlassRim {
                z: 10
                radius: pillBg.radius
                deepBevel: true
            }

            // Done / "Dictation inserted" state (shared across Classic & Compact)
            RowLayout {
                id: doneRow

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 16
                spacing: 10
                visible: root.isDone
                opacity: root.isDone ? 1.0 : 0.0

                Behavior on opacity {
                    enabled: VoiceTyping.enableAnimations
                    NumberAnimation {
                        duration: Math.max(80, Math.round(160 / VoiceTyping.speedFactor))
                        easing.type: Easing.OutCubic
                    }
                }

                StyledRect {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: Qt.alpha(Colours.palette.m3success, 0.22)
                    border.color: Qt.alpha(Colours.palette.m3success, 0.45)
                    border.width: 1

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "check"
                        color: Colours.palette.m3success
                        fontStyle: Tokens.font.icon.small
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: VoiceTyping.statusText
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }
            }

            // -----------------------------------------------------------------
            // CLASSIC THEME (Two-line recording pill)
            // -----------------------------------------------------------------
            RowLayout {
                id: classicRow

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                visible: root.isClassicMode && !root.isDone

                // Left circular badge
                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + (root.isListening ? 8 : 0)
                        height: parent.height + (root.isListening ? 8 : 0)
                        radius: width / 2
                        color: Qt.alpha(root.accentColor, root.isListening ? 0.16 : 0.0)

                        SequentialAnimation on opacity {
                            running: root.isListening && VoiceTyping.enableAnimations
                            loops: Animation.Infinite

                            NumberAnimation {
                                from: 0.3
                                to: 0.9
                                duration: Math.max(300, Math.round(700 / VoiceTyping.speedFactor))
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 0.9
                                to: 0.3
                                duration: Math.max(300, Math.round(700 / VoiceTyping.speedFactor))
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(root.accentColor, root.isListening ? 0.22 : 0.14)
                        border.color: Qt.alpha(root.accentColor, root.isListening ? 0.45 : 0.28)
                        border.width: 1

                        MaterialIcon {
                            anchors.centerIn: parent
                            color: root.accentColor
                            fontStyle: Tokens.font.icon.small
                            text: root.isPaused ? "pause" : root.isTranscribing ? "hourglass_top" : "mic"
                        }
                    }
                }

                // Middle two-line text stack
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            Layout.alignment: Qt.AlignVCenter
                            radius: 3
                            color: root.accentColor

                            SequentialAnimation on opacity {
                                running: root.isListening && VoiceTyping.enableAnimations
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: 0.45
                                    to: 1.0
                                    duration: Math.max(250, Math.round(550 / VoiceTyping.speedFactor))
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: 1.0
                                    to: 0.45
                                    duration: Math.max(250, Math.round(550 / VoiceTyping.speedFactor))
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: VoiceTyping.statusText
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.hasTranscript
                        text: root.transcriptText
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideLeft
                    }
                }

                // Right capsule dot waveform
                VoiceDotWave {
                    Layout.alignment: Qt.AlignVCenter
                    visible: VoiceTyping.liveWaveform
                    dotCount: 9
                    inCapsule: true
                    active: VoiceTyping.active && !root.isDone
                    paused: root.isPaused
                    animate: VoiceTyping.enableAnimations
                    speedFactor: VoiceTyping.speedFactor
                    barLevels: VoiceTyping.barLevels
                    activeColor: root.accentColor
                }

                // Hover close button
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.showCloseButton
                    icon: "close"
                    type: IconButton.Text
                    opacity: 0.78
                    onClicked: VoiceTyping.cancel()
                }
            }

            // -----------------------------------------------------------------
            // COMPACT THEME (Single-row recording pill)
            // -----------------------------------------------------------------
            RowLayout {
                id: compactRow

                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8
                visible: root.isCompactMode && !root.isDone

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    color: root.accentColor
                    fontStyle: Tokens.font.icon.small
                    text: root.isPaused ? "pause" : root.isTranscribing ? "hourglass_top" : "mic"
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.hasTranscript ? root.transcriptText : VoiceTyping.statusText
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurface
                    elide: root.hasTranscript ? Text.ElideLeft : Text.ElideRight
                }

                VoiceDotWave {
                    Layout.alignment: Qt.AlignVCenter
                    visible: VoiceTyping.liveWaveform
                    dotCount: 6
                    inCapsule: false
                    dotSize: 2.8
                    dotSpacing: 2.5
                    maxDotHeight: 13
                    active: VoiceTyping.active && !root.isDone
                    paused: root.isPaused
                    animate: VoiceTyping.enableAnimations
                    speedFactor: VoiceTyping.speedFactor
                    barLevels: VoiceTyping.barLevels
                    activeColor: root.accentColor
                }

                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.showCloseButton
                    icon: "close"
                    type: IconButton.Text
                    opacity: 0.78
                    onClicked: VoiceTyping.cancel()
                }
            }
        }

        // =========================================================================
        // 2. DYNAMIC WAVE THEME (Floating audio ribbons + central glass badge)
        // =========================================================================
        Item {
            id: waveRoot

            anchors.fill: parent
            visible: root.isWaveMode

            Item {
                id: waveHeader

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 50

                VoiceWaveCanvas {
                    id: waveCanvas

                    anchors.fill: parent
                    visible: VoiceTyping.liveWaveform || !root.isDone
                    active: VoiceTyping.active
                    paused: root.isPaused
                    done: root.isDone
                    animate: VoiceTyping.enableAnimations
                    speedFactor: VoiceTyping.speedFactor
                    audioLevel: VoiceTyping.liveWaveform ? VoiceTyping.audioLevel : (root.isListening ? 0.16 : 0.0)
                    barLevels: VoiceTyping.liveWaveform ? VoiceTyping.barLevels : [0.12, 0.16, 0.14, 0.12]
                    centerHoleRadius: 21
                    primaryColor: root.accentColor
                    secondaryColor: Colours.palette.m3onSurface
                }

                // Central frosted circular mic / check badge (blurred by Hyprland)
                StyledRect {
                    id: waveBadge

                    anchors.centerIn: parent
                    width: 42
                    height: 42
                    radius: width / 2
                    color: root.isDone
                        ? Qt.alpha(Colours.palette.m3surface, Colours.transparency.enabled ? 0.84 : 1.0)
                        : root.surfaceColor

                    GlassRim {
                        z: 10
                        radius: waveBadge.radius
                        deepBevel: true
                    }

                    // Subtle status halo inside circle when listening or done
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: width / 2
                        color: root.isDone
                            ? Qt.alpha(Colours.palette.m3success, 0.18)
                            : root.isPaused
                                ? Qt.alpha(Colours.palette.m3tertiary, 0.14)
                                : "transparent"
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        fontStyle: Tokens.font.icon.medium
                        color: root.isDone
                            ? Colours.palette.m3success
                            : root.isPaused
                                ? Colours.palette.m3tertiary
                                : Colours.palette.m3onSurface
                        text: root.isDone
                            ? "check"
                            : root.isPaused
                                ? "pause"
                                : root.isTranscribing
                                    ? "hourglass_top"
                                    : "mic"
                    }
                }
            }

            // Floating live transcript text underneath the wave ribbons
            StyledText {
                id: waveTranscriptText

                anchors.top: waveHeader.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 24, implicitWidth)
                visible: root.hasTranscript
                text: root.transcriptText
                font: Tokens.font.mono.small
                color: Colours.palette.m3onSurface
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideLeft

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.82)
                    shadowBlur: 0.45
                    shadowVerticalOffset: 1
                }
            }
        }
    }
}
