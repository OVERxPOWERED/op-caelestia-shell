import "cards"
import qs.config
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var props
    required property var visibilities

    spacing: Appearance.spacing.normal

    IdleInhibit {}

    Record {
        props: root.props
        visibilities: root.visibilities
    }

    Toggles {
        visibilities: root.visibilities
    }
}
