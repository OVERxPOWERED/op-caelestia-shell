import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();
        CalendarService;
        Displays;
        DockPins;
        WorkspaceManager;
        Density;
        Glass;
        Motion;
        AppFonts;
        DoctorWatchdog;
        VoiceTyping;
        ClipboardSettings;
        HyprSunset;
        FocusLedger;
        FocusTimer;
        ScreenTime;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
