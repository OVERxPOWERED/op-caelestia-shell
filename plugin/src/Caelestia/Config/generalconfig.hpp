#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

class GeneralApps : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QStringList, terminal, { QStringLiteral("foot") })
    CONFIG_GLOBAL_PROPERTY(QStringList, audio, { QStringLiteral("pavucontrol") })
    CONFIG_GLOBAL_PROPERTY(QStringList, playback, { QStringLiteral("mpv") })
    CONFIG_GLOBAL_PROPERTY(QStringList, explorer, { QStringLiteral("thunar") })

public:
    explicit GeneralApps(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralIdle : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, lockBeforeSleep, true)
    CONFIG_GLOBAL_PROPERTY(bool, inhibitWhenAudio, true)
    CONFIG_GLOBAL_PROPERTY(QVariantList, timeouts)

public:
    explicit GeneralIdle(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralBattery : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QVariantList, warnLevels)
    CONFIG_GLOBAL_PROPERTY(int, criticalLevel, 3)

public:
    explicit GeneralBattery(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(QString, logo)
    CONFIG_PROPERTY(qreal, mediaGifSpeedAdjustment, 300)
    CONFIG_PROPERTY(qreal, sessionGifSpeed, 0.7)
    CONFIG_SUBOBJECT(GeneralApps, apps)
    CONFIG_SUBOBJECT(GeneralIdle, idle)
    CONFIG_SUBOBJECT(GeneralBattery, battery)

public:
    explicit GeneralConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_apps(new GeneralApps(this))
        , m_idle(new GeneralIdle(this))
        , m_battery(new GeneralBattery(this)) {}
};

} // namespace caelestia::config
