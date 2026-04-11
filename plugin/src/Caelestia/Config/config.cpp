#include "config.hpp"
#include "configscope.hpp"
#include "monitorconfigmanager.hpp"
#include "tokens.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

GlobalConfig::GlobalConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceConfig(this))
    , m_general(new GeneralConfig(this))
    , m_background(new BackgroundConfig(this))
    , m_bar(new BarConfig(this))
    , m_border(new BorderConfig(this))
    , m_dashboard(new DashboardConfig(this))
    , m_controlCenter(new ControlCenterConfig(this))
    , m_launcher(new LauncherConfig(this))
    , m_notifs(new NotifsConfig(this))
    , m_osd(new OsdConfig(this))
    , m_session(new SessionConfig(this))
    , m_winfo(new WInfoConfig(this))
    , m_lock(new LockConfig(this))
    , m_utilities(new UtilitiesConfig(this))
    , m_sidebar(new SidebarConfig(this))
    , m_services(new ServiceConfig(this))
    , m_paths(new UserPaths(this)) {
    setupFileBackend(configDir() + QStringLiteral("shell.json"));
}

GlobalConfig::GlobalConfig(GlobalConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceConfig(this))
    , m_general(new GeneralConfig(this))
    , m_background(new BackgroundConfig(this))
    , m_bar(new BarConfig(this))
    , m_border(new BorderConfig(this))
    , m_dashboard(new DashboardConfig(this))
    , m_controlCenter(new ControlCenterConfig(this))
    , m_launcher(new LauncherConfig(this))
    , m_notifs(new NotifsConfig(this))
    , m_osd(new OsdConfig(this))
    , m_session(new SessionConfig(this))
    , m_winfo(new WInfoConfig(this))
    , m_lock(new LockConfig(this))
    , m_utilities(new UtilitiesConfig(this))
    , m_sidebar(new SidebarConfig(this))
    , m_services(new ServiceConfig(this))
    , m_paths(new UserPaths(this)) {
    if (!filePath.isEmpty())
        setupFileBackend(filePath, screen);
    if (fallback)
        syncFromGlobal(fallback);

    // Bind appearance computed properties to token base values
    bindAppearanceTokens();
}

GlobalConfig* GlobalConfig::instance() {
    static GlobalConfig instance;
    instance.bindAppearanceTokens();
    return &instance;
}

GlobalConfig* GlobalConfig::defaults() {
    if (!m_defaults)
        m_defaults = new GlobalConfig(nullptr, QString(), QString(), this);
    return m_defaults;
}

void GlobalConfig::bindAppearanceTokens() {
    if (m_tokensBound)
        return;

    qCDebug(lcConfig) << "GlobalConfig::bindAppearanceTokens: binding appearance to token values";
    auto* const tokenAppearance = TokenConfig::instance()->appearance();
    m_appearance->rounding()->bindTokens(tokenAppearance->rounding());
    m_appearance->spacing()->bindTokens(tokenAppearance->spacing());
    m_appearance->padding()->bindTokens(tokenAppearance->padding());
    m_appearance->font()->size()->bindTokens(tokenAppearance->fontSize());
    m_appearance->anim()->durations()->bindTokens(tokenAppearance->animDurations());
    m_tokensBound = true;
}

GlobalConfig* GlobalConfig::forScreen(const QString& screen) {
    return MonitorConfigManager::instance()->configForScreen(screen);
}

GlobalConfig* GlobalConfig::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

// Config (attached type)

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

// Helper: return per-monitor sub-object if scope exists, otherwise global
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
