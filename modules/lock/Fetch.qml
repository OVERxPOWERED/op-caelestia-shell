pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

StyledClippingRect {
    id: root

    required property real rootHeight
    readonly property bool showGif: Config.lock.showGif
    readonly property string gifSource: Paths.absolutePath(Config.paths.lockGif)
    readonly property int cBoxSize: Tokens.font.body.medium.pointSize * 2
    property int lastFrame: -1
    property bool manualPlayback: false
    property int stillTicks: 0

    implicitHeight: root.showGif
        ? Math.max(190, Math.min(root.rootHeight * 0.42, width * 0.72))
        : (fetchLayout.implicitHeight + fetchLayout.anchors.topMargin + fetchLayout.anchors.margins)
    radius: root.showGif ? Tokens.rounding.extraLarge : Tokens.rounding.medium
    color: root.showGif ? "transparent" : Colours.tPalette.m3surfaceContainer

    // GIF Display Mode
    AnimatedImage {
        id: gifPlayer

        anchors.fill: parent
        visible: root.showGif

        source: root.showGif ? root.gifSource : ""
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
        playing: root.visible && root.showGif && width > 0 && height > 0
        paused: false
        speed: 1
        asynchronous: true
        cache: false
        fillMode: AnimatedImage.PreserveAspectCrop

        onSourceChanged: {
            root.lastFrame = -1;
            root.manualPlayback = false;
            root.stillTicks = 0;
            paused = false;
        }

        onStatusChanged: {
            if (status === AnimatedImage.Ready) {
                root.manualPlayback = false;
                paused = false;
                currentFrame = 0;
            }
        }
    }

    Timer {
        interval: root.manualPlayback ? 120 : 700
        repeat: true
        running: root.visible && root.showGif && gifPlayer.status === AnimatedImage.Ready && gifPlayer.frameCount > 1

        onTriggered: {
            if (gifPlayer.paused)
                gifPlayer.paused = false;

            if (root.manualPlayback) {
                gifPlayer.currentFrame = (gifPlayer.currentFrame + 1) % gifPlayer.frameCount;
                root.lastFrame = gifPlayer.currentFrame;
                return;
            }

            if (gifPlayer.currentFrame !== root.lastFrame) {
                root.lastFrame = gifPlayer.currentFrame;
                root.stillTicks = 0;
                return;
            }

            if (++root.stillTicks < 2)
                return;

            root.stillTicks = 0;
            root.manualPlayback = true;
            gifPlayer.currentFrame = (gifPlayer.currentFrame + 1) % gifPlayer.frameCount;
            root.lastFrame = gifPlayer.currentFrame;
        }
    }

    // System Information Fetch Mode
    ColumnLayout {
        id: fetchLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        anchors.topMargin: Tokens.padding.extraLarge
        anchors.bottomMargin: Tokens.padding.extraLarge
        visible: !root.showGif

        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: prompt.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: prompt.implicitHeight + Tokens.padding.small * 2

                color: Colours.palette.m3primary
                radius: Tokens.rounding.medium

                MonoText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    color: Colours.palette.m3onPrimary
                }
            }

            MonoText {
                Layout.fillWidth: true
                text: "caelestiafetch.sh"
                elide: Text.ElideRight
            }

            WrappedLoader {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.preferredHeight: 0
                active: !iconLoader.active && !root.showGif

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraLarge

            WrappedLoader {
                id: iconLoader

                Layout.fillHeight: true
                active: !root.showGif && root.width > Tokens.sizes.lock.largeLogoWidth

                sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.medium
                Layout.bottomMargin: iconLoader.active || colourRowLoader.active ? Tokens.padding.medium : 0
                spacing: Tokens.spacing.medium

                Repeater {
                    model: {
                        if (root.showGif)
                            return [];

                        const items = [];
                        const hasBatt = UPower.displayDevice.isLaptopBattery;
                        const rHeight = root.rootHeight;

                        if (!hasBatt && rHeight > Tokens.sizes.lock.fetch4LinesHeight)
                            items.push(`OS  : ${SysInfo.osPrettyName || SysInfo.osName}`);

                        if (rHeight > (hasBatt ? Tokens.sizes.lock.fetch4LinesHeight : Tokens.sizes.lock.fetch3LinesHeight))
                            items.push(`WM  : ${SysInfo.wm}`);

                        if (!hasBatt || rHeight > Tokens.sizes.lock.fetch3LinesHeight)
                            items.push(`USER: ${SysInfo.user}`);

                        items.push(`UP  : ${SysInfo.uptime}`);

                        if (hasBatt)
                            items.push(`BATT: ${[UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state) ? "(+) " : ""}${Math.round(UPower.displayDevice.percentage * 100)}%`);

                        return items;
                    }

                    MonoText {
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                }
            }
        }

        WrappedLoader {
            id: colourRowLoader

            Layout.topMargin: iconLoader.active ? Tokens.spacing.small : 0
            Layout.alignment: Qt.AlignHCenter
            active: !root.showGif && root.rootHeight > Tokens.sizes.lock.showColourBoxRowHeight

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: CUtils.clamp(Math.floor((fetchLayout.width + coloursRow.spacing) / (root.cBoxSize + coloursRow.spacing)), 0, 8)

                    StyledRect {
                        required property int index

                        implicitWidth: implicitHeight
                        implicitHeight: root.cBoxSize
                        color: Colours.palette[`term${index}`]
                        radius: Tokens.rounding.medium
                    }
                }
            }
        }
    }

    Component {
        id: caelestiaLogo

        Logo {
            width: height
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: height
            colour: Colours.palette.m3primary
            layer.enabled: Config.lock.recolourLogo
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component MonoText: StyledText {
        font: root.width > Tokens.sizes.lock.largeFontWidth ? Tokens.font.mono.medium : Tokens.font.mono.small
    }
}
