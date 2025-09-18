import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var visibilities

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal
    }
}
