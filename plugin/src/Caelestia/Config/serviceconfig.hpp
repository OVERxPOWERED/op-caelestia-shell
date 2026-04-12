#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

class ServiceConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation)
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheit, false)
    CONFIG_GLOBAL_PROPERTY(bool, useFahrenheitPerformance, false)
    CONFIG_GLOBAL_PROPERTY(bool, useTwelveHourClock, false)
    CONFIG_GLOBAL_PROPERTY(QString, gpuType)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 45)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, QStringLiteral("Spotify"))
    CONFIG_GLOBAL_PROPERTY(QVariantList, playerAliases)
    CONFIG_GLOBAL_PROPERTY(bool, showLyrics, false)
    CONFIG_GLOBAL_PROPERTY(QString, lyricsBackend, QStringLiteral("Auto"))

public:
    explicit ServiceConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
