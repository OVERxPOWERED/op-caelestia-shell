import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config

Scope {
    Connections {
        function onLoaded(): void {
            if (GlobalConfig.utilities.toasts.configLoaded)
                Toaster.toast(qsTr("Config loaded"), qsTr("Config loaded successfully!"), "rule_settings");
        }

        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to parse config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onSaveFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to save config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Error);
        }

        target: GlobalConfig
    }

    Connections {
        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to parse token config%1").arg(screen ? "for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        target: TokenConfig
    }
}
