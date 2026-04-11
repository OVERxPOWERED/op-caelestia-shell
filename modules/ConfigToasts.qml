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

        function onLoadFailed(error: string): void {
            Toaster.toast(qsTr("Failed to read config file"), error, "settings_alert", Toast.Warning);
        }

        function onSaveFailed(error: string): void {
            Toaster.toast(qsTr("Failed to save config"), error, "settings_alert", Toast.Error);
        }

        target: GlobalConfig
    }

    Connections {
        function onLoadFailed(error: string): void {
            Toaster.toast(qsTr("Failed to read token config file"), error, "settings_alert", Toast.Warning);
        }

        target: TokenConfig
    }
}
