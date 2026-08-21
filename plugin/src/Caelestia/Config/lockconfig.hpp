#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, enableHowdy, true)
    CONFIG_GLOBAL_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_GLOBAL_PROPERTY(bool, enablePattern, true)
    CONFIG_GLOBAL_PROPERTY(QString, pattern, u"74159"_s)
    CONFIG_PROPERTY(bool, hideNotifs, false)

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
