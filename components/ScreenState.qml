import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
    property bool dock

    property var launcherPickCallback: undefined

    onLauncherChanged: {
        if (launcher) dock = false;
    }

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
