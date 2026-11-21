import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.utils
import "center"

Item {
    id: root

    required property var lock
    property Item blurSource: null
    property real revealProgress: 0

    readonly property string designStyle: Config.lock.designStyle || "hud"
    readonly property bool isEditorial: designStyle === "editorial"
    readonly property bool isHud: designStyle === "hud"
    readonly property bool isHero: designStyle === "hero"

    readonly property int edgePad: Math.max(Tokens.padding.extraLarge * 2, Math.round(Math.min(width, height) * 0.045))
    readonly property int cardWidth: Math.round(Math.min(380, Math.max(280, width * 0.21)))
    readonly property bool fetchBehindCenter: Config.lock.showFetch && Config.lock.showGif && Config.lock.fetchPlacement === "center"
    readonly property bool fetchInMediaGroup: Config.lock.showFetch && !fetchBehindCenter
    property bool layoutReady: false

    function widgetX(pos: string, w: real): real {
        if (pos.endsWith("-left") || pos === "left")
            return edgePad;
        if (pos.endsWith("-right") || pos === "right")
            return width - w - edgePad;
        return (width - w) / 2;
    }

    function widgetY(pos: string, h: real): real {
        if (pos.startsWith("top-"))
            return edgePad;
        if (pos.startsWith("bottom-"))
            return height - h - edgePad;
        return (height - h) / 2;
    }

    // Subtle inward offset when revealProgress = 0 so cards gently drift into place
    function enterOffsetX(itemX: real, itemW: real): real {
        return ((width / 2) - (itemX + itemW / 2)) * (1 - revealProgress) * 0.07;
    }

    function enterOffsetY(itemY: real, itemH: real): real {
        return ((height / 2) - (itemY + itemH / 2)) * (1 - revealProgress) * 0.07;
    }

    onWidthChanged: if (width > 0 && height > 0 && !layoutReady) layoutReady = true
    onHeightChanged: if (width > 0 && height > 0 && !layoutReady) layoutReady = true

    // Soft vignette for contrast in borderless / hero layouts
    Rectangle {
        anchors.fill: parent
        visible: root.isEditorial || root.isHero
        opacity: root.revealProgress * 0.35
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    // Hero top-left clock + date + inline weather
    LockSlot {
        position: "top-left"
        visible: root.isHero && (Config.lock.showClock || Config.lock.showWeather)
        width: heroHeader.width
        height: heroHeader.height

        ColumnLayout {
            id: heroHeader

            spacing: Tokens.spacing.small

            Clock {
                visible: Config.lock.showClock
                centerScale: Math.min(1, (root.lock.screen?.height ?? 1440) / 1440) * 1.05
                centerWidth: Math.round(Tokens.sizes.lock.centerWidth * centerScale)
            }

            StyledText {
                visible: Config.lock.showClock
                text: Time.format("dddd • d MMMM").toUpperCase()
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
            }

            RowLayout {
                visible: Config.lock.showWeather
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: Weather.icon
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    text: `${Weather.temp}  •  ${Weather.description}`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.title.small
                }
            }
        }
    }

    LockSlot {
        id: weatherSlot

        position: Config.lock.weatherPosition
        visible: !root.isHero && Config.lock.showWeather
        width: weatherCard.width
        height: weatherCard.height

        WeatherInfo {
            id: weatherCard

            width: root.cardWidth
            rootHeight: root.height
            blurSource: root.blurSource
            absX: weatherSlot.x
            absY: weatherSlot.y
            compact: root.isEditorial || root.isHud
            borderless: root.isEditorial
        }
    }

    LockSlot {
        id: mediaSlot

        position: Config.lock.mediaPosition
        visible: Config.lock.showMedia || root.fetchInMediaGroup
        width: mediaGroup.width
        height: mediaGroup.height

        Item {
            id: mediaGroup

            readonly property bool fetchVisible: root.fetchInMediaGroup
            readonly property bool mediaVisible: Config.lock.showMedia
            readonly property bool fetchOnBottom: Config.lock.fetchPlacement === "bottom"
            readonly property int gap: (fetchVisible && mediaVisible) ? Tokens.spacing.medium : 0
            readonly property real fetchHeight: Config.lock.showGif
                ? Math.round(Math.min(280, Math.max(180, root.height * 0.24)))
                : fetchCard.implicitHeight

            width: root.cardWidth
            height: (fetchVisible ? fetchHeight : 0) + gap + (mediaVisible ? mediaCard.height : 0)

            Fetch {
                id: fetchCard

                visible: mediaGroup.fetchVisible
                width: root.cardWidth
                height: mediaGroup.fetchHeight
                y: (!mediaGroup.fetchOnBottom || !mediaGroup.mediaVisible) ? 0 : (mediaCard.height + mediaGroup.gap)
                rootHeight: root.height
            }

            Media {
                id: mediaCard

                visible: mediaGroup.mediaVisible
                width: root.cardWidth
                y: (mediaGroup.fetchOnBottom || !mediaGroup.fetchVisible) ? 0 : (fetchCard.height + mediaGroup.gap)
                lock: root.lock
                blurSource: root.blurSource
                absX: mediaSlot.x
                absY: mediaSlot.y + y
                borderless: root.isEditorial
                compactLayout: root.isEditorial || root.isHud || root.isHero
            }
        }
    }

    LockSlot {
        id: centerSlot

        position: Config.lock.centerPosition
        baseScale: 0.96
        width: centerGifCard.visible ? centerGifCard.width : centerCard.width
        height: centerGifCard.visible ? centerGifCard.height : centerCard.height

        StyledClippingRect {
            id: centerGifCard

            visible: root.fetchBehindCenter
            anchors.centerIn: parent
            width: centerCard.width + Tokens.padding.extraLarge * 2
            height: Math.min(root.height - root.edgePad * 2, centerCard.height + Tokens.padding.extraLarge * 4)
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            antialiasing: true

            AnimatedImage {
                anchors.fill: parent
                source: centerGifCard.visible ? Paths.absolutePath(Config.paths.lockGif) : ""
                playing: centerGifCard.visible && root.visible
                speed: 1
                asynchronous: true
                fillMode: AnimatedImage.PreserveAspectCrop
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.26)
            }

            GlassRim {
                z: 10
                radius: centerGifCard.radius
            }
        }

        Center {
            id: centerCard

            anchors.centerIn: parent
            lock: root.lock
            blurSource: centerGifCard.visible ? centerGifCard : root.blurSource
            absX: centerGifCard.visible ? x : (centerSlot.x + x)
            absY: centerGifCard.visible ? y : (centerSlot.y + y)
            hideClockOverride: root.isHero
        }
    }

    LockSlot {
        id: resourcesSlot

        position: Config.lock.resourcesPosition
        visible: Config.lock.showResources
        width: resourcesCard.width
        height: resourcesCard.height

        Resources {
            id: resourcesCard

            width: root.cardWidth
            blurSource: root.blurSource
            absX: resourcesSlot.x
            absY: resourcesSlot.y
            borderless: root.isEditorial
        }
    }

    LockSlot {
        id: notifsSlot

        position: Config.lock.notifsPosition
        visible: Config.lock.showNotifs
        width: notifsCard.width
        height: notifsCard.height

        StyledRect {
            id: notifsCard

            width: root.cardWidth
            height: root.isHud
                ? Math.round(Math.min(300, Math.max(200, root.height * 0.26)))
                : Math.round(Math.min(400, Math.max(240, root.height * 0.32)))
            radius: Tokens.rounding.extraLarge
            color: "transparent"
            antialiasing: true

            GlassBackdrop {
                visible: !root.isEditorial && root.blurSource !== null
                blurSource: root.blurSource
                absX: notifsSlot.x
                absY: notifsSlot.y
                radius: parent.radius
            }

            GlassRim {
                z: 10
                visible: !root.isEditorial
                radius: parent.radius
            }

            NotifDock {
                lock: root.lock
            }
        }
    }

    component LockSlot: Item {
        id: slot

        required property string position
        property real baseScale: 0.96

        x: root.widgetX(position, width)
        y: root.widgetY(position, height)
        opacity: root.revealProgress
        scale: baseScale + (1 - baseScale) * root.revealProgress

        transform: Translate {
            x: root.enterOffsetX(slot.x, slot.width)
            y: root.enterOffsetY(slot.y, slot.height)
        }

        Behavior on x {
            enabled: root.layoutReady

            Anim {}
        }

        Behavior on y {
            enabled: root.layoutReady

            Anim {}
        }
    }
}
