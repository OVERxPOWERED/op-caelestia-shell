import "performance"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: placeholder.active ? Tokens.sizes.dashboard.perfPlaceholderWidth : content.implicitWidth
    implicitHeight: placeholder.active ? placeholder.implicitHeight + Tokens.padding.extraLarge * 2 : content.implicitHeight

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: !Config.dashboard.performance.showCpu && !(Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None) && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork && !(UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery)
        asynchronous: true

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.topMargin: -Tokens.spacing.small
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No widgets enabled")
                font: Tokens.font.title.large
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enable widgets in the dashboard settings")
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
        visible: !placeholder.active

        ServiceRef {
            service: root.Config.dashboard.performance.showCpu ? Cpu : null
        }

        ServiceRef {
            service: root.Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None ? Gpu : null
        }

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: Config.dashboard.performance.showCpu || (Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None)

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.dashboard.performance.showCpu
                    icon: "memory"
                    label: qsTr("CPU")
                    subLabel: Cpu.name
                    usage: Cpu.percentage
                    temperature: Cpu.temperature
                    accent: Colours.palette.m3primary
                }

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None
                    icon: "desktop_windows"
                    label: qsTr("GPU")
                    subLabel: Gpu.name
                    usage: Gpu.percentage
                    temperature: Gpu.temperature
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
            Layout.fillHeight: true
            visible: UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery
        }
    }
}
