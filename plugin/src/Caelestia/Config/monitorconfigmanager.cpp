#include "monitorconfigmanager.hpp"
#include "config.hpp"
#include "tokens.hpp"

#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString monitorConfigDir(const QString& screen) {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
           QStringLiteral("/caelestia/monitors/") + screen + QStringLiteral("/");
}

} // namespace

MonitorConfigManager::MonitorConfigManager(QObject* parent)
    : QObject(parent) {}

MonitorConfigManager* MonitorConfigManager::instance() {
    static MonitorConfigManager instance;
    return &instance;
}

MonitorConfigManager* MonitorConfigManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

GlobalConfig* MonitorConfigManager::configForScreen(const QString& screen) {
    auto& overlay = m_overlays[screen];
    if (!overlay.config) {
        auto dir = monitorConfigDir(screen);
        overlay.config = new GlobalConfig(GlobalConfig::instance(), dir + QStringLiteral("shell.json"), this);
    }
    return overlay.config;
}

TokenConfig* MonitorConfigManager::tokensForScreen(const QString& screen) {
    auto& overlay = m_overlays[screen];
    if (!overlay.tokens) {
        auto dir = monitorConfigDir(screen);
        overlay.tokens = new TokenConfig(TokenConfig::instance(), dir + QStringLiteral("shell-tokens.json"), this);
    }
    return overlay.tokens;
}

} // namespace caelestia::config
