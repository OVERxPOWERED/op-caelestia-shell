import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property color accent: Colours.palette.m3secondary
    readonly property real percentage: SystemUsage.primaryDisk?.perc ?? 0

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.extraLarge
        spacing: 0

        RowLayout {
            id: row

            spacing: Tokens.spacing.large

            CircularProgress {
                fgColour: root.accent
                value: root.percentage
                implicitSize: usageColumn.implicitHeight + thickness + Tokens.padding.large * 2
                startAngle: -225
                sweepAngle: 270

                Behavior on clampedVal {
                    Anim {}
                }

                ColumnLayout {
                    id: usageColumn

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hard_drive"
                        color: root.accent
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(root.percentage * 100) + "%"
                        font: Tokens.font.title.builders.large.width(90).build()
                        color: root.accent
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Used")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                Layout.minimumWidth: Tokens.sizes.dashboard.perfStorageTextWidth
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: qsTr("Storage")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    text: {
                        if (!SystemUsage.primaryDisk)
                            return qsTr("No disks detected");

                        const usedFmt = SystemUsage.formatKib(SystemUsage.primaryDisk.used);
                        const totalFmt = SystemUsage.formatKib(SystemUsage.primaryDisk.total);
                        return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                    }
                    font: Tokens.font.body.large
                    color: root.accent
                }
            }
        }

        SplitButton {
            Layout.alignment: Qt.AlignHCenter

            type: SplitButton.Tonal
            disabled: !SystemUsage.disks.length
            fallbackIcon: "storage"
            fallbackText: qsTr("No disks")
            menuOnTop: true
            minLeftWidth: row.implicitWidth * 0.6

            menuItems: disks.instances
            active: menuItems.find(m => m.modelData === SystemUsage.primaryDisk) ?? menuItems[0] ?? null
            menu.onItemSelected: item => SystemUsage.manualPrimaryDisk = (item as DiskItem).modelData

            Variants {
                id: disks

                model: SystemUsage.disks

                DiskItem {}
            }
        }
    }

    component DiskItem: MenuItem {
        required property var modelData

        icon: modelData === SystemUsage.primaryDisk ? "check" : ""
        text: modelData.mount
        activeIcon: "storage"
    }
}
