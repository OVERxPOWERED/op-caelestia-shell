#include "configscope.hpp"

namespace caelestia::config {

ConfigScope::ConfigScope(QQuickItem* parent)
    : QQuickItem(parent) {}

ConfigScope* ConfigScope::find(QObject* object) {
    auto* item = qobject_cast<QQuickItem*>(object);

    while (item) {
        if (auto* scope = qobject_cast<ConfigScope*>(item))
            return scope;
        item = item->parentItem();
    }

    return nullptr;
}

} // namespace caelestia::config
