#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>

namespace caelestia::config {

class SessionIcons : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, logout, QStringLiteral("logout"))
    CONFIG_PROPERTY(QString, shutdown, QStringLiteral("power_settings_new"))
    CONFIG_PROPERTY(QString, hibernate, QStringLiteral("downloading"))
    CONFIG_PROPERTY(QString, reboot, QStringLiteral("cached"))

public:
    explicit SessionIcons(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionCommands : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QStringList, logout, { QStringLiteral("loginctl"), QStringLiteral("terminate-user"), QString() })
    CONFIG_PROPERTY(QStringList, shutdown, { QStringLiteral("systemctl"), QStringLiteral("poweroff") })
    CONFIG_PROPERTY(QStringList, hibernate, { QStringLiteral("systemctl"), QStringLiteral("hibernate") })
    CONFIG_PROPERTY(QStringList, reboot, { QStringLiteral("systemctl"), QStringLiteral("reboot") })

public:
    explicit SessionCommands(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, dragThreshold, 30)
    CONFIG_PROPERTY(bool, vimKeybinds, false)
    CONFIG_SUBOBJECT(SessionIcons, icons)
    CONFIG_SUBOBJECT(SessionCommands, commands)

public:
    explicit SessionConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_icons(new SessionIcons(this))
        , m_commands(new SessionCommands(this)) {}
};

} // namespace caelestia::config
