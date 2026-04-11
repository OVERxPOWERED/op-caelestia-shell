#include "monitorconfigmanager.hpp"
#include "config.hpp"
#include "tokens.hpp"

#include <qstandardpaths.h>

namespace caelestia::config {

MonitorConfigManager* MonitorConfigManager::s_instance = nullptr;

namespace {

QString monitorConfigDir(const QString& screen) {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
           QStringLiteral("/caelestia/monitors/") + screen + QStringLiteral("/");
}

} // namespace

MonitorConfigManager::MonitorConfigManager(QObject* parent)
    : QObject(parent) {
    s_instance = this;
}

MonitorConfigManager::~MonitorConfigManager() {
    s_instance = nullptr;
}

MonitorConfigManager* MonitorConfigManager::instance() {
    return s_instance;
}

MonitorConfigManager* MonitorConfigManager::create(QQmlEngine* engine, QJSEngine*) {
    return new MonitorConfigManager(engine);
}

GlobalConfig* MonitorConfigManager::configForScreen(const QString& screen) {
    auto it = m_overlays.find(screen);
    if (it != m_overlays.end() && it->config)
        return it->config;

    auto* global = GlobalConfig::instance();
    if (!global)
        return nullptr;

    auto dir = monitorConfigDir(screen);
    auto* overlay = new GlobalConfig(global, dir + QStringLiteral("shell.json"), this);

    m_overlays[screen].config = overlay;
    return overlay;
}

TokenConfig* MonitorConfigManager::tokensForScreen(const QString& screen) {
    auto it = m_overlays.find(screen);
    if (it != m_overlays.end() && it->tokens)
        return it->tokens;

    auto* global = TokenConfig::instance();
    if (!global)
        return nullptr;

    auto dir = monitorConfigDir(screen);
    auto* overlay = new TokenConfig(global, dir + QStringLiteral("shell-tokens.json"), this);

    m_overlays[screen].tokens = overlay;
    return overlay;
}

} // namespace caelestia::config
