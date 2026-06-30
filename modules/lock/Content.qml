import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    spacing: Tokens.spacing.largeIncreased * 2

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Fetch {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 190
            Layout.preferredHeight: root.height * 0.42
            rootHeight: root.height
        }

        Media {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            lock: root.lock
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Resources {
            Layout.fillWidth: true
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Tokens.rounding.extraLarge
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
