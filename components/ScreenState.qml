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
    property bool overview
    property bool quicknote
    property bool clipboard

    property var launcherPickCallback: undefined

    onClipboardChanged: {
        if (clipboard) {
            dock = false;
            overview = false;
            launcher = false;
            dashboard = false;
            session = false;
            quicknote = false;
        }
    }

    onQuicknoteChanged: {
        if (quicknote) {
            dock = false;
            overview = false;
            launcher = false;
            dashboard = false;
            session = false;
            clipboard = false;
        }
    }

    onLauncherChanged: {
        if (!launcher)
            launcherPickCallback = undefined;
        else {
            dock = false;
            overview = false;
            quicknote = false;
            dashboard = false;
            session = false;
            clipboard = false;
        }
    }

    onOverviewChanged: {
        if (overview) {
            launcher = false;
            quicknote = false;
            clipboard = false;
            dashboard = false;
            session = false;
        }
    }

    onDashboardChanged: {
        if (dashboard) {
            launcher = false;
            overview = false;
            session = false;
        }
    }

    onSessionChanged: {
        if (session) {
            launcher = false;
            overview = false;
            dashboard = false;
        }
    }

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
    property bool freezeFocus
}
