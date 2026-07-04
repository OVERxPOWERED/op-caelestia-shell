#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>

namespace caelestia::config {

class DockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, maxSlots, 5)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_GLOBAL_PROPERTY(QStringList, pinnedApps)

public:
    explicit DockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
