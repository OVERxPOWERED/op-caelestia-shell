#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

class ServiceConfig : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(QString, weatherLocation)
    CONFIG_PROPERTY(bool, useFahrenheit, false)
    CONFIG_PROPERTY(bool, useFahrenheitPerformance, false)
    CONFIG_PROPERTY(bool, useTwelveHourClock, false)
    CONFIG_PROPERTY(QString, gpuType)
    CONFIG_PROPERTY(int, visualiserBars, 45)
    CONFIG_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_PROPERTY(bool, smartScheme, true)
    CONFIG_PROPERTY(QString, defaultPlayer, QStringLiteral("Spotify"))
    CONFIG_PROPERTY(QVariantList, playerAliases)
    CONFIG_PROPERTY(bool, showLyrics, false)
    CONFIG_PROPERTY(QString, lyricsBackend, QStringLiteral("Auto"))

public:
    explicit ServiceConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
