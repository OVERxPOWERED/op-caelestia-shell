pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property int rootHeight

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Tokens.padding.extraLargeIncreased

    spacing: Tokens.spacing.small

    Loader {
        asynchronous: true
        Layout.topMargin: Tokens.padding.extraLargeIncreased
        Layout.bottomMargin: -Tokens.padding.large
        Layout.alignment: Qt.AlignHCenter

        active: root.rootHeight > 610
        visible: active

        sourceComponent: StyledText {
            text: qsTr("Weather")
            color: Colours.palette.m3primary
            font: Tokens.font.body.builders.large.size(28).weight(500).build()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.largeIncreased

        MaterialIcon {
            animate: true
            text: Weather.icon
            color: Colours.palette.m3secondary
            font: Tokens.font.icon.builders.extraLarge.size(Tokens.font.icon.extraLarge.pointSize * 2.5).build()
        }

        ColumnLayout {
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: Weather.description
                color: Colours.palette.m3secondary
                font: Tokens.font.body.builders.large.weight(500).build()
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: qsTr("Humidity: %1%").arg(Weather.humidity)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }
        }

        Loader {
            asynchronous: true
            Layout.rightMargin: Tokens.padding.small
            active: root.width > 400
            visible: active

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: Weather.temp
                    color: Colours.palette.m3primary
                    horizontalAlignment: Text.AlignRight
                    font: Tokens.font.body.builders.large.size(28).weight(500).build()
                    elide: Text.ElideLeft
                }

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: qsTr("Feels like: %1").arg(Weather.feelsLike)
                    color: Colours.palette.m3outline
                    horizontalAlignment: Text.AlignRight
                    font: Tokens.font.body.small
                    elide: Text.ElideLeft
                }
            }
        }
    }

    Loader {
        id: forecastLoader

        asynchronous: true
        Layout.topMargin: Tokens.spacing.medium
        Layout.bottomMargin: Tokens.padding.extraLargeIncreased
        Layout.fillWidth: true

        active: root.rootHeight > 820
        visible: active

        sourceComponent: RowLayout {
            spacing: Tokens.spacing.largeIncreased

            Repeater {
                model: {
                    const forecast = Weather.hourlyForecast;
                    const count = root.width < 320 ? 3 : root.width < 400 ? 4 : 5;
                    if (!forecast)
                        return Array.from({
                            length: count
                        }, () => null);

                    return forecast.slice(0, count);
                }

                ColumnLayout {
                    id: forecastHour

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const hour = forecastHour.modelData?.hour ?? 0;
                            return hour > 12 ? `${(hour - 12).toString().padStart(2, "0")} PM` : `${hour.toString().padStart(2, "0")} AM`;
                        }
                        color: Colours.palette.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        font: Tokens.font.body.large
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: forecastHour.modelData?.icon ?? "cloud_alert"
                        font: Tokens.font.icon.builders.extraLarge.size(Tokens.font.icon.extraLarge.pointSize * 1.5).weight(500).build()
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: GlobalConfig.services.useFahrenheit ? `${forecastHour.modelData?.tempF ?? 0}°F` : `${forecastHour.modelData?.tempC ?? 0}°C`
                        color: Colours.palette.m3secondary
                        font: Tokens.font.body.large
                    }
                }
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }
}
