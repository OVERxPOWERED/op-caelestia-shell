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
    property bool _bulkUpdating: false

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
    property bool freezeFocus

    function toggleAll(): void {
        const open = !(launcher || dashboard || osd || utilities);
        _bulkUpdating = true;
        if (open) {
            dock = false;
            overview = false;
            quicknote = false;
            session = false;
            clipboard = false;
        }
        utilities = open;
        osd = open;
        dashboard = open;
        launcher = open;
        _bulkUpdating = false;
    }

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
        else if (!_bulkUpdating) {
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
        if (dashboard && !_bulkUpdating) {
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
}
