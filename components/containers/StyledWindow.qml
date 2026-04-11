import Quickshell
import Quickshell.Wayland
import Caelestia.Config

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    required property string name
    default property alias contentData: scope.data

    WlrLayershell.namespace: `caelestia-${name}`
    color: "transparent"

    ConfigScope {
        id: scope

        anchors.fill: parent
        screen: root.screen.name
    }
}
