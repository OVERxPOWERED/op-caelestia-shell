import "performance"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Internal
import qs.components
import qs.components.misc
import qs.services

Item {
    id: root

    readonly property int minWidth: 400 + 400 + Tokens.spacing.medium + 120 + Tokens.padding.extraLargeIncreased

    function displayTemp(temp: real): string {
        return `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? temp * 1.8 + 32 : temp)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`;
    }

    implicitWidth: Math.max(minWidth, content.implicitWidth)
    implicitHeight: placeholder.visible ? placeholder.height : content.implicitHeight

    StyledRect {
        id: placeholder

        anchors.centerIn: parent
        width: 400
        height: 350
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainer
        visible: !Config.dashboard.performance.showCpu && !(Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE") && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork && !(UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No widgets enabled")
                font: Tokens.font.body.large
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enable widgets in dashboard settings")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium
        visible: !placeholder.visible

        Ref {
            service: SystemUsage
        }

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: Config.dashboard.performance.showCpu || (Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE")

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.dashboard.performance.showCpu
                    icon: "memory"
                    label: qsTr("CPU")
                    subLabel: SystemUsage.cpuName
                    usage: SystemUsage.cpuPerc
                    temperature: SystemUsage.cpuTemp
                    accent: Colours.palette.m3primary
                }

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.dashboard.performance.showGpu && SystemUsage.gpuType !== "NONE"
                    icon: "desktop_windows"
                    label: qsTr("GPU")
                    subLabel: SystemUsage.gpuName
                    usage: SystemUsage.gpuPerc
                    temperature: SystemUsage.gpuTemp
                    accent: Colours.palette.m3secondary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork

                GaugeCard {
                    Layout.minimumWidth: 250
                    Layout.preferredHeight: 220
                    Layout.fillWidth: !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork
                    icon: "memory_alt"
                    title: qsTr("Memory")
                    percentage: SystemUsage.memPerc
                    subtitle: {
                        const usedFmt = SystemUsage.formatKib(SystemUsage.memUsed);
                        const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                        return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                    }
                    accentColor: Colours.palette.m3tertiary
                    visible: Config.dashboard.performance.showMemory
                }

                StorageCard {
                    Layout.fillHeight: true
                    visible: Config.dashboard.performance.showStorage
                }

                NetworkCard {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 200
                    Layout.preferredHeight: 220
                    visible: Config.dashboard.performance.showNetwork
                }
            }
        }

        BatteryTank {
            Layout.preferredWidth: 120
            Layout.preferredHeight: mainColumn.implicitHeight
            visible: UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery
        }
    }

    component BatteryTank: StyledClippingRect {
        id: batteryTank

        property real percentage: UPower.displayDevice.percentage
        property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging
        property color accentColor: Colours.palette.m3primary
        property real animatedPercentage: 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge
        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage

        // Background Fill
        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * batteryTank.animatedPercentage
            color: Qt.alpha(batteryTank.accentColor, 0.15)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: {
                        if (!UPower.displayDevice.isLaptopBattery) {
                            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                return "energy_savings_leaf";

                            if (PowerProfiles.profile === PowerProfile.Performance)
                                return "rocket_launch";

                            return "balance";
                        }
                        if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                            return "battery_full";

                        const perc = UPower.displayDevice.percentage;
                        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                        if (perc >= 0.99)
                            return "battery_full";

                        let level = Math.floor(perc * 7);
                        if (charging && (level === 4 || level === 1))
                            level--;

                        return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                    }
                    fontStyle: Tokens.font.icon.large
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Battery")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurface
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Bottom Info Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: -4

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${Math.round(batteryTank.percentage * 100)}%`
                    font: Tokens.font.body.builders.large.size(28).weight(Font.Medium).build()
                    color: batteryTank.accentColor
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: {
                        if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                            return qsTr("Full");

                        if (batteryTank.isCharging)
                            return qsTr("Charging");

                        const s = UPower.displayDevice.timeToEmpty;
                        if (s === 0)
                            return qsTr("...");

                        const hr = Math.floor(s / 3600);
                        const min = Math.floor((s % 3600) / 60);
                        if (hr > 0)
                            return `${hr}h ${min}m`;

                        return `${min}m`;
                    }
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Behavior on animatedPercentage {
            Anim {
                type: Anim.StandardLarge
            }
        }
    }

    component CardHeader: RowLayout {
        property string icon
        property string title
        property color accentColor: Colours.palette.m3primary

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: parent.icon
            fill: 1
            color: parent.accentColor
            fontStyle: Tokens.font.icon.size(Tokens.spacing.large).build()
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.title
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }
    }

    component ProgressBar: StyledRect {
        id: progressBar

        property real value: 0
        property color fgColor: Colours.palette.m3primary
        property color bgColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        property real animatedValue: 0

        color: bgColor
        radius: Tokens.rounding.full
        Component.onCompleted: animatedValue = value
        onValueChanged: animatedValue = value

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * progressBar.animatedValue
            color: progressBar.fgColor
            radius: Tokens.rounding.full
        }

        Behavior on animatedValue {
            Anim {
                type: Anim.StandardLarge
            }
        }
    }

    component GaugeCard: StyledRect {
        id: gaugeCard

        property string icon
        property string title
        property real percentage: 0
        property string subtitle
        property color accentColor: Colours.palette.m3primary
        readonly property real arcStartAngle: 0.75 * Math.PI
        readonly property real arcSweep: 1.5 * Math.PI
        property real animatedPercentage: 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge
        clip: true
        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            CardHeader {
                icon: gaugeCard.icon
                title: gaugeCard.title
                accentColor: gaugeCard.accentColor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ArcGauge {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    percentage: gaugeCard.animatedPercentage
                    accentColor: gaugeCard.accentColor
                    trackColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    startAngle: gaugeCard.arcStartAngle
                    sweepAngle: gaugeCard.arcSweep
                }

                StyledText {
                    anchors.centerIn: parent
                    text: `${Math.round(gaugeCard.percentage * 100)}%`
                    font: Tokens.font.body.builders.large.size(28).weight(Font.Medium).build()
                    color: gaugeCard.accentColor
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeCard.subtitle
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Behavior on animatedPercentage {
            Anim {
                type: Anim.StandardLarge
            }
        }
    }

    component NetworkCard: StyledRect {
        id: networkCard

        property color accentColor: Colours.palette.m3primary

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge
        clip: true

        Ref {
            service: NetworkUsage
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            CardHeader {
                icon: "swap_vert"
                title: qsTr("Network")
                accentColor: networkCard.accentColor
            }

            // Sparkline graph
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                SparklineItem {
                    id: sparkline

                    property real targetMax: 1024
                    property real smoothMax: targetMax

                    anchors.fill: parent
                    line1: NetworkUsage.uploadBuffer // qmllint disable missing-type
                    line1Color: Colours.palette.m3secondary
                    line1FillAlpha: 0.15
                    line2: NetworkUsage.downloadBuffer // qmllint disable missing-type
                    line2Color: Colours.palette.m3tertiary
                    line2FillAlpha: 0.2
                    maxValue: smoothMax
                    historyLength: NetworkUsage.historyLength

                    Connections {
                        function onValuesChanged(): void {
                            sparkline.targetMax = Math.max(NetworkUsage.downloadBuffer.maximum, NetworkUsage.uploadBuffer.maximum, 1024);
                            slideAnim.restart();
                        }

                        target: NetworkUsage.downloadBuffer
                    }

                    NumberAnimation {
                        id: slideAnim

                        target: sparkline
                        property: "slideProgress"
                        from: 0
                        to: 1
                        duration: GlobalConfig.dashboard.resourceUpdateInterval
                    }

                    Behavior on smoothMax {
                        Anim {
                            type: Anim.StandardLarge
                        }
                    }
                }

                // "No data" placeholder
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Collecting data...")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    visible: NetworkUsage.downloadBuffer.count < 2
                    opacity: 0.6
                }
            }

            // Download row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "download"
                    color: Colours.palette.m3tertiary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Download")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: Colours.palette.m3tertiary
                }
            }

            // Upload row
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "upload"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Upload")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    color: Colours.palette.m3secondary
                }
            }

            // Session totals
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "history"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Total")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: {
                        const down = NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal ?? 0);
                        const up = NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal ?? 0);
                        return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
                    }
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
