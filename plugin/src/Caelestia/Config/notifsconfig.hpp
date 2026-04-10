#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class NotifsConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, expire, true)
    CONFIG_PROPERTY(QString, fullscreen, QStringLiteral("on"))
    CONFIG_PROPERTY(int, defaultExpireTimeout, 5000)
    CONFIG_PROPERTY(qreal, clearThreshold, 0.3)
    CONFIG_PROPERTY(int, expandThreshold, 20)
    CONFIG_PROPERTY(bool, actionOnClick, false)
    CONFIG_PROPERTY(int, groupPreviewNum, 3)
    CONFIG_PROPERTY(bool, openExpanded, false)

public:
    explicit NotifsConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
