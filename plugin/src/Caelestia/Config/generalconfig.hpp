#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

class GeneralApps : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QStringList, terminal, { QStringLiteral("foot") })
    CONFIG_PROPERTY(QStringList, audio, { QStringLiteral("pavucontrol") })
    CONFIG_PROPERTY(QStringList, playback, { QStringLiteral("mpv") })
    CONFIG_PROPERTY(QStringList, explorer, { QStringLiteral("thunar") })

public:
    explicit GeneralApps(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralIdle : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, lockBeforeSleep, true)
    CONFIG_PROPERTY(bool, inhibitWhenAudio, true)
    CONFIG_PROPERTY(QVariantList, timeouts)

public:
    explicit GeneralIdle(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralBattery : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QVariantList, warnLevels)
    CONFIG_PROPERTY(int, criticalLevel, 3)

public:
    explicit GeneralBattery(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class GeneralConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, logo)
    CONFIG_PROPERTY(QStringList, excludedScreens)
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
