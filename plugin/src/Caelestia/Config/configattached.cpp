#include "configattached.hpp"
#include "config.hpp"
#include "configscope.hpp"
#include "monitorconfigmanager.hpp"

namespace caelestia::config {

Config::Config(ConfigScope* scope, QObject* parent)
    : QObject(parent)
    , m_scope(scope) {
    connectScope();
}

void Config::connectScope() {
    if (!m_scope)
        return;
    connect(m_scope, &ConfigScope::configChanged, this, &Config::sourceChanged);
    connect(m_scope, &ConfigScope::tokensChanged, this, &Config::sourceChanged);
}

#define CONFIG_ATTACHED_GETTER(Type, name)                                                                             \
    const Type* Config::name() const {                                                                                 \
        if (m_scope && m_scope->config())                                                                              \
            return m_scope->config()->name();                                                                          \
        return GlobalConfig::instance()->name();                                                                       \
    }

CONFIG_ATTACHED_GETTER(AppearanceConfig, appearance)
CONFIG_ATTACHED_GETTER(GeneralConfig, general)
CONFIG_ATTACHED_GETTER(BackgroundConfig, background)
CONFIG_ATTACHED_GETTER(BarConfig, bar)
CONFIG_ATTACHED_GETTER(BorderConfig, border)
CONFIG_ATTACHED_GETTER(DashboardConfig, dashboard)
CONFIG_ATTACHED_GETTER(ControlCenterConfig, controlCenter)
CONFIG_ATTACHED_GETTER(LauncherConfig, launcher)
CONFIG_ATTACHED_GETTER(NotifsConfig, notifs)
CONFIG_ATTACHED_GETTER(OsdConfig, osd)
CONFIG_ATTACHED_GETTER(SessionConfig, session)
CONFIG_ATTACHED_GETTER(WInfoConfig, winfo)
CONFIG_ATTACHED_GETTER(LockConfig, lock)
CONFIG_ATTACHED_GETTER(UtilitiesConfig, utilities)
CONFIG_ATTACHED_GETTER(SidebarConfig, sidebar)
CONFIG_ATTACHED_GETTER(ServiceConfig, services)
CONFIG_ATTACHED_GETTER(UserPaths, paths)

#undef CONFIG_ATTACHED_GETTER

GlobalConfig* Config::forScreen(const QString& screen) {
    return GlobalConfig::forScreen(screen);
}

Config* Config::qmlAttachedProperties(QObject* object) {
    return new Config(ConfigScope::find(object), object);
}

} // namespace caelestia::config
