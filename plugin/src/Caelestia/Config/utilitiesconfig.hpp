#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

class UtilitiesToasts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, configLoaded, true)
    CONFIG_PROPERTY(QString, fullscreen, QStringLiteral("off"))
    CONFIG_PROPERTY(bool, chargingChanged, true)
    CONFIG_PROPERTY(bool, gameModeChanged, true)
    CONFIG_PROPERTY(bool, dndChanged, true)
    CONFIG_PROPERTY(bool, audioOutputChanged, true)
    CONFIG_PROPERTY(bool, audioInputChanged, true)
    CONFIG_PROPERTY(bool, capsLockChanged, true)
    CONFIG_PROPERTY(bool, numLockChanged, true)
    CONFIG_PROPERTY(bool, kbLayoutChanged, true)
    CONFIG_PROPERTY(bool, kbLimit, true)
    CONFIG_PROPERTY(bool, vpnChanged, true)
    CONFIG_PROPERTY(bool, nowPlaying, false)

public:
    explicit UtilitiesToasts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesVpn : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QVariantList, provider)

public:
    explicit UtilitiesVpn(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, maxToasts, 4)
    CONFIG_SUBOBJECT(UtilitiesToasts, toasts)
    CONFIG_SUBOBJECT(UtilitiesVpn, vpn)
    CONFIG_PROPERTY(QVariantList, quickToggles)

public:
    explicit UtilitiesConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_toasts(new UtilitiesToasts(this))
        , m_vpn(new UtilitiesVpn(this)) {}
};

} // namespace caelestia::config
