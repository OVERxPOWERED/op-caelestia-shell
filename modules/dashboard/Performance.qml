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

                StorageCard {
                    Layout.fillHeight: true
                    visible: Config.dashboard.performance.showStorage
                }

                NetworkCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Config.dashboard.performance.showNetwork
                }

                MemoryCard {
                    Layout.fillHeight: true
                    visible: Config.dashboard.performance.showMemory
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
}
