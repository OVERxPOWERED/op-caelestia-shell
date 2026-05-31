pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property int rootHeight // TODO: add forecast when large height

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
    radius: Tokens.rounding.extraExtraLarge
    color: Colours.tPalette.m3surfaceContainer

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: Weather.description
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.large
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.medium

            StyledText {
                id: temp

                animate: true
                text: Weather.temp
                color: Colours.palette.m3primary
                font: Tokens.font.headline.builders.large.scale(1.5).weight(Font.DemiBold).width(80).build()
            }

            MaterialIcon {
                animate: true
                text: Weather.icon
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.headline.builders.large.scale(1.5).build()
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: qsTr("Feels like %1").arg(Weather.temp)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            animate: true
            text: {
                const today = Weather.forecast[0];
                return qsTr("High %1 • Low %2").arg(Weather.formatTemp(today?.maxTempC)).arg(Weather.formatTemp(today?.minTempC));
            }
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }
    }
}
