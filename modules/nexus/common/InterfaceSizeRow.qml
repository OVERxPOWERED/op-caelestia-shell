import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services

// Text and spacing of the shell on one display. Shared by Display and Look & feel, and both
// read and write the same per-display setting, so they always agree.
SelectRow {
    id: root

    required property string screenName
    property bool showName

    readonly property real size: Displays.interfaceSize(screenName)

    label: showName ? Tr.tr("Interface size · %1").arg(screenName) : Tr.tr("Interface size")
    subtext: Tr.tr("Text and spacing of the shell on this display only")
    fallbackText: `${Math.round(size * 100)}%`
    menuItems: items.instances
    onSelected: item => Displays.setInterfaceSize(root.screenName, item.value)

    Binding {
        target: root
        property: "active"
        value: items.instances.find(i => Math.abs(i.value - root.size) < 0.001) ?? null
    }

    Variants {
        id: items

        model: [0.8, 0.85, 0.9, 1, 1.1, 1.25, 1.5]

        MenuItem {
            required property real modelData

            text: `${Math.round(modelData * 100)}%`
            value: modelData
        }
    }
}
