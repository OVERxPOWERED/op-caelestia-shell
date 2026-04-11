#include "configscope.hpp"
#include "monitorconfigmanager.hpp"

namespace caelestia::config {

ConfigScope::ConfigScope(QQuickItem* parent)
    : QQuickItem(parent) {}

void ConfigScope::setScreen(const QString& screen) {
    if (m_screen == screen)
        return;

    m_screen = screen;
    emit screenChanged();
    resolveConfig();
}

void ConfigScope::resolveConfig() {
    GlobalConfig* newConfig = nullptr;
    TokenConfig* newTokens = nullptr;

    if (!m_screen.isEmpty()) {
        if (auto* mgr = MonitorConfigManager::instance()) {
            newConfig = mgr->configForScreen(m_screen);
            newTokens = mgr->tokensForScreen(m_screen);
        }
    }

    if (m_config != newConfig) {
        m_config = newConfig;
        emit configChanged();
    }

    if (m_tokens != newTokens) {
        m_tokens = newTokens;
        emit tokensChanged();
    }
}

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
