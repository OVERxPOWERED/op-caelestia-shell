#pragma once

#include <qqmlintegration.h>
#include <qquickitem.h>

namespace caelestia::config {

class ConfigScope : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ConfigScope(QQuickItem* parent = nullptr);

    static ConfigScope* find(QObject* object);
};

} // namespace caelestia::config
