pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    readonly property var tabDefs: ({
        dashboard: {
            id: "dashboard",
            component: dashComponent,
            iconName: "dashboard",
            text: Tr.tr("Dashboard"),
            enabled: Config.dashboard.showDashboard
        },
        media: {
            id: "media",
            component: mediaComponent,
            iconName: "queue_music",
            text: Tr.tr("Media"),
            enabled: Config.dashboard.showMedia
        },
        focus: {
            id: "focus",
            component: focusComponent,
            iconName: "timer",
            text: Tr.tr("Focus"),
            enabled: Config.dashboard.showFocus
        },
        performance: {
            id: "performance",
            component: performanceComponent,
            iconName: "speed",
            text: Tr.tr("Performance"),
            enabled: Config.dashboard.showPerformance
        },
        weather: {
            id: "weather",
            component: weatherComponent,
            iconName: "cloud",
            text: Tr.tr("Weather"),
            enabled: Config.dashboard.showWeather
        }
    })

    readonly property var dashboardTabs: {
        const tabsConfig = Config.dashboard.tabs;
        if (tabsConfig && tabsConfig.values && tabsConfig.values.length > 0) {
            const seenIds = new Set();
            const list = [];
            for (const entry of tabsConfig.values) {
                if (!entry.enabled || seenIds.has(entry.id))
                    continue;
                seenIds.add(entry.id);
                const def = tabDefs[entry.id];
                if (def)
                    list.push(def);
            }
            return list;
        }

        const defaultOrder = ["dashboard", "media", "focus", "performance", "weather"];
        return defaultOrder
            .map(id => tabDefs[id])
            .filter(def => def && def.enabled);
    }

    readonly property real nonAnimWidth: dashboardTabs.length > 0 ? view.implicitWidth + viewWrapper.anchors.margins * 2 : 0
    readonly property real nonAnimHeight: dashboardTabs.length > 0 ? tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2 : 0

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: CUtils.clamp(anchors.margins - Config.border.thickness, 0, anchors.margins)
        anchors.margins: Tokens.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        screenState: root.screenState
        tabs: root.dashboardTabs
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.large
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.screenState.dashboardTab
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 2)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 10)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    delegate: Loader {
                        id: paneLoader

                        required property int index
                        required property var modelData

                        Layout.alignment: Qt.AlignTop

                        sourceComponent: modelData.component

                        Component.onCompleted: active = Qt.binding(() => {
                            if (index === view.currentIndex)
                                return true;
                            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                            return (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
                        })
                    }
                }
            }

            Component {
                id: dashComponent

                Dash {
                    screenState: root.screenState
                    facePicker: root.facePicker
                }
            }

            Component {
                id: mediaComponent

                Media {
                    screenState: root.screenState
                }
            }

            Component {
                id: performanceComponent

                Performance {}
            }

            Component {
                id: weatherComponent

                WeatherTab {}
            }

            Component {
                id: focusComponent

                FocusTab {}
            }

            Behavior on contentX {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
