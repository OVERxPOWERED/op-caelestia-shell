#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

class LauncherUseFuzzy : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, apps, false)
    CONFIG_GLOBAL_PROPERTY(bool, actions, false)
    CONFIG_GLOBAL_PROPERTY(bool, schemes, false)
    CONFIG_GLOBAL_PROPERTY(bool, variants, false)
    CONFIG_GLOBAL_PROPERTY(bool, wallpapers, false)

public:
    explicit LauncherUseFuzzy(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LauncherConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, maxShown, 7)
    CONFIG_PROPERTY(int, maxWallpapers, 9)
    CONFIG_GLOBAL_PROPERTY(QString, specialPrefix, QStringLiteral("@"))
    CONFIG_GLOBAL_PROPERTY(QString, actionPrefix, QStringLiteral(">"))
    CONFIG_GLOBAL_PROPERTY(bool, enableDangerousActions, false)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_GLOBAL_PROPERTY(bool, vimKeybinds, false)
    CONFIG_GLOBAL_PROPERTY(QStringList, favouriteApps)
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenApps)
    CONFIG_SUBOBJECT(LauncherUseFuzzy, useFuzzy)
    CONFIG_GLOBAL_PROPERTY(QVariantList, actions)

public:
    explicit LauncherConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_useFuzzy(new LauncherUseFuzzy(this)) {}
};

} // namespace caelestia::config
