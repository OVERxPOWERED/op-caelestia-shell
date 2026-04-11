pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property Session session

    // General Settings
    property bool enabled: Config.dashboard.enabled ?? true
    property bool showOnHover: Config.dashboard.showOnHover ?? true
    property int mediaUpdateInterval: Config.dashboard.mediaUpdateInterval ?? 1000
    property int resourceUpdateInterval: Config.dashboard.resourceUpdateInterval ?? 1000
    property int dragThreshold: Config.dashboard.dragThreshold ?? 50

    // Dashboard Tabs
    property bool showDashboard: Config.dashboard.showDashboard ?? true
    property bool showMedia: Config.dashboard.showMedia ?? true
    property bool showPerformance: Config.dashboard.showPerformance ?? true
    property bool showWeather: Config.dashboard.showWeather ?? true

    // Performance Resources
    property bool showBattery: Config.dashboard.performance.showBattery ?? false
    property bool showGpu: Config.dashboard.performance.showGpu ?? true
    property bool showCpu: Config.dashboard.performance.showCpu ?? true
    property bool showMemory: Config.dashboard.performance.showMemory ?? true
    property bool showStorage: Config.dashboard.performance.showStorage ?? true
    property bool showNetwork: Config.dashboard.performance.showNetwork ?? true

    function saveConfig() {
        Config.dashboard.enabled = root.enabled;
        Config.dashboard.showOnHover = root.showOnHover;
        Config.dashboard.mediaUpdateInterval = root.mediaUpdateInterval;
        Config.dashboard.resourceUpdateInterval = root.resourceUpdateInterval;
        Config.dashboard.dragThreshold = root.dragThreshold;
        Config.dashboard.showDashboard = root.showDashboard;
        Config.dashboard.showMedia = root.showMedia;
        Config.dashboard.showPerformance = root.showPerformance;
        Config.dashboard.showWeather = root.showWeather;
        Config.dashboard.performance.showBattery = root.showBattery;
        Config.dashboard.performance.showGpu = root.showGpu;
        Config.dashboard.performance.showCpu = root.showCpu;
        Config.dashboard.performance.showMemory = root.showMemory;
        Config.dashboard.performance.showStorage = root.showStorage;
        Config.dashboard.performance.showNetwork = root.showNetwork;
        // Note: sizes properties are readonly and cannot be modified
    }

    anchors.fill: parent

    ClippingRectangle {
        id: dashboardClippingRect

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Tokens.padding.normal

        radius: dashboardBorder.innerRadius
        color: "transparent"

        Loader {
            id: dashboardLoader

            anchors.fill: parent
            anchors.margins: Tokens.padding.large + Tokens.padding.normal
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large

            asynchronous: true
            sourceComponent: dashboardContentComponent
        }
    }

    InnerBorder {
        id: dashboardBorder

        leftThickness: 0
        rightThickness: Tokens.padding.normal
    }

    Component {
        id: dashboardContentComponent

        StyledFlickable {
            id: dashboardFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: dashboardLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: dashboardFlickable
            }

            ColumnLayout {
                id: dashboardLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Tokens.spacing.normal

                RowLayout {
                    spacing: Tokens.spacing.smaller

                    StyledText {
                        text: qsTr("Dashboard")
                        font.pointSize: Tokens.font.size.large
                        font.weight: 500
                    }
                }

                // General Settings Section
                GeneralSection {
                    rootItem: root
                }

                // Performance Resources Section
                PerformanceSection {
                    rootItem: root
                }
            }
        }
    }
}
