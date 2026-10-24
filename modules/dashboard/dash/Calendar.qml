pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property ScreenState screenState

    property date currentDate: screenState.dashboardDate
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()
    readonly property int nonAnimCurrMonth: screenState.dashboardDate.getMonth()
    readonly property int nonAnimCurrYear: screenState.dashboardDate.getFullYear()

    readonly property int animDirection: screenState.dashboardDate > currentDate ? -1 : 1
    property real animTranslate
    property real animOpacity: 1

    property Item hoveredDayItem: null
    property var hoveredDate: null
    property var hoveredEvents: []
    property bool tooltipOpen: false
    property bool tooltipPinned: false

    function formatTimeStr(t: string): string {
        if (!t || t.indexOf(":") === -1) return t;
        if (!Units.twelveHourClock) return t;
        const parts = t.split(":");
        let h = parseInt(parts[0], 10);
        const m = parts[1];
        const ampm = h >= 12 ? "PM" : "AM";
        h = h % 12 || 12;
        return `${h}:${m} ${ampm}`;
    }

    function formatEventRange(start: string, end: string): string {
        if (!start) return "";
        const fStart = formatTimeStr(start);
        if (!end || end === start) return fStart;
        const fEnd = formatTimeStr(end);
        return `${fStart} – ${fEnd}`;
    }

    Timer {
        id: hoverTimer
        interval: 300
        onTriggered: {
            if (root.hoveredDayItem && root.hoveredEvents.length > 0)
                root.tooltipOpen = true;
        }
    }

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: {
            if (!root.tooltipPinned)
                root.tooltipOpen = false;
        }
    }

    onCurrentDateChanged: {
        root.tooltipOpen = false;
        root.tooltipPinned = false;
    }

    function onWheel(event: WheelEvent): void {
        root.tooltipOpen = false;
        root.tooltipPinned = false;
        if (event.angleDelta.y > 0)
            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            screenState.dashboardDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.screenState.dashboardDate = new Date()

    Anim {
        id: trOutAnim

        running: false
        target: root
        property: "animTranslate"
        to: root.Tokens.padding.extraLarge * root.animDirection
        type: Anim.FastSpatial
    }

    Behavior on currentDate {
        SequentialAnimation {
            ParallelAnimation {
                ScriptAction {
                    script: Qt.callLater(() => trOutAnim.start())
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 0
                    type: Anim.FastEffects
                }
            }
            ScriptAction {
                script: {
                    trOutAnim.complete();
                    root.animTranslate = root.Tokens.padding.extraLarge * -root.animDirection;
                }
            }
            PropertyAction {}
            ParallelAnimation {
                Anim {
                    target: root
                    property: "animTranslate"
                    to: 0
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 1
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            IconButton {
                isRound: true
                icon: "chevron_left"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.large * 2
                implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.extraSmall * 2

                StateLayer {
                    color: Colours.palette.m3primary
                    radius: pressed ? Tokens.rounding.small : height / 2
                    disabled: {
                        const now = new Date();
                        return root.nonAnimCurrMonth === now.getMonth() && root.nonAnimCurrYear === now.getFullYear();
                    }
                    onClicked: root.screenState.dashboardDate = new Date()

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledText {
                    id: monthYearDisplay

                    opacity: root.animOpacity
                    transform: Translate {
                        x: root.animTranslate
                    }

                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                }
            }

            IconButton {
                isRound: true
                icon: "chevron_right"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.screenState.dashboardDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            opacity: root.animOpacity
            transform: Translate {
                x: root.animTranslate
            }

            MonthGrid {
                id: grid

                month: root.currMonth
                year: root.currYear

                anchors.fill: parent

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model

                    readonly property var dayEvents: CalendarService.getEvents(dayItem.model.date)
                    readonly property bool hasEvents: dayEvents.length > 0

                    implicitWidth: implicitHeight
                    implicitHeight: text.implicitHeight + Tokens.padding.small + 4

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: dayItem.hasEvents ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onEntered: {
                            if (dayItem.hasEvents) {
                                root.hoveredDayItem = dayItem;
                                root.hoveredDate = dayItem.model.date;
                                root.hoveredEvents = dayItem.dayEvents;
                                hoverTimer.restart();
                            }
                        }

                        onExited: {
                            hoverTimer.stop();
                            if (!root.tooltipPinned)
                                hideTimer.restart();
                        }

                        onClicked: {
                            if (dayItem.hasEvents) {
                                if (root.tooltipPinned && root.hoveredDate === dayItem.model.date) {
                                    root.tooltipPinned = false;
                                    root.tooltipOpen = false;
                                } else {
                                    root.hoveredDayItem = dayItem;
                                    root.hoveredDate = dayItem.model.date;
                                    root.hoveredEvents = dayItem.dayEvents;
                                    root.tooltipPinned = true;
                                    root.tooltipOpen = true;
                                }
                            } else {
                                root.tooltipPinned = false;
                                root.tooltipOpen = false;
                            }
                        }
                    }

                    StyledText {
                        id: text

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: dayItem.hasEvents ? -2 : 0

                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            const dayOfWeek = dayItem.model.date.getDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3tertiary;

                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font: Tokens.font.body.small
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 1
                        spacing: 2
                        visible: dayItem.hasEvents && (dayItem.model.month === grid.month || dayItem.model.today)

                        Repeater {
                            model: Math.min(3, dayItem.dayEvents.length)

                            Rectangle {
                                required property int index
                                width: 3
                                height: 3
                                radius: 1.5
                                color: (dayItem.dayEvents[index] && dayItem.dayEvents[index].color) ? dayItem.dayEvents[index].color : Colours.palette.m3primary
                            }
                        }
                    }
                }
            }

            MaterialShape {
                id: todayIndicator

                readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
                property Item today

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today ? today.y - Tokens.padding.extraSmall - 1 : 0

                implicitSize: today ? Math.max(today.implicitWidth, today.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                shape: MaterialShape.Sunny

                clip: true
                color: Colours.palette.m3primary

                opacity: todayItem ? 1 : 0

                Colouriser {
                    x: -todayIndicator.x
                    y: -todayIndicator.y

                    implicitWidth: grid.width
                    implicitHeight: grid.height

                    source: grid
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary
                }
            }
        }
    }

    // Event Tooltip Popover Card
    StyledRect {
        id: tooltipCard

        z: 100
        visible: opacity > 0
        opacity: root.tooltipOpen ? 1 : 0
        scale: root.tooltipOpen ? 1 : 0.94

        Behavior on opacity {
            Anim { type: Anim.FastEffects }
        }
        Behavior on scale {
            Anim { type: Anim.FastSpatial }
        }

        readonly property point dayPos: root.hoveredDayItem
            ? root.hoveredDayItem.mapToItem(root, root.hoveredDayItem.width / 2, root.hoveredDayItem.height)
            : Qt.point(0, 0)

        x: Math.max(Tokens.padding.small, Math.min(root.width - width - Tokens.padding.small, dayPos.x - width / 2))
        y: (dayPos.y + height + Tokens.padding.small <= root.height)
            ? (dayPos.y + 6)
            : Math.max(Tokens.padding.small, dayPos.y - (root.hoveredDayItem ? root.hoveredDayItem.height : 0) - height - 6)

        implicitWidth: Math.min(260, root.width - Tokens.padding.medium * 2)
        implicitHeight: tooltipLayout.implicitHeight + Tokens.padding.medium * 2

        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Tokens.rounding.medium
        border.color: Colours.palette.m3outlineVariant
        border.width: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hideTimer.stop()
            onExited: {
                if (!root.tooltipPinned)
                    hideTimer.restart();
            }
        }

        ColumnLayout {
            id: tooltipLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: "calendar_month"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.hoveredDate ? Qt.formatDate(root.hoveredDate, "dddd, MMM d") : ""
                    font: Tokens.font.title.builders.small.weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                IconButton {
                    visible: root.tooltipPinned
                    isRound: true
                    icon: "close"
                    type: IconButton.Text
                    padding: 2
                    font: Tokens.font.icon.builders.small.scale(0.8).build()
                    onClicked: {
                        root.tooltipPinned = false;
                        root.tooltipOpen = false;
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.hoveredEvents

                    delegate: RowLayout {
                        id: eventRow

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: eventRow.modelData.color || Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: eventRow.modelData.summary || Tr.tr("Untitled event")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: {
                                if (eventRow.modelData.allDay)
                                    return Tr.tr("All day");
                                return root.formatEventRange(eventRow.modelData.startTime, eventRow.modelData.endTime);
                            }
                            font: Tokens.font.body.builders.extraSmall.scale(0.95).build()
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
