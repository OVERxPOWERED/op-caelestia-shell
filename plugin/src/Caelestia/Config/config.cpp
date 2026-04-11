#include "config.hpp"
#include "configscope.hpp"
#include "tokens.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

GlobalConfig* s_instance = nullptr;

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

GlobalConfig::GlobalConfig(QObject* parent)
    : ConfigObject(parent)
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
    // Set global instance
    s_instance = this;

    setupFileBackend(configDir() + QStringLiteral("shell.json"));

    // If TokenConfig was created before us, bind now
    if (TokenConfig::instance())
        bindAppearanceTokens();
}

GlobalConfig::GlobalConfig(GlobalConfig* fallback, const QString& filePath, QObject* parent)
    : ConfigObject(parent)
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
    setSparse(true);
    if (!filePath.isEmpty())
        setupFileBackend(filePath);
    if (fallback)
        syncFromGlobal(fallback);
}

GlobalConfig::~GlobalConfig() {
    if (s_instance == this)
        s_instance = nullptr;
}

GlobalConfig* GlobalConfig::instance() {
    return s_instance;
}

GlobalConfig* GlobalConfig::defaults() {
    if (!m_defaults)
        m_defaults = new GlobalConfig(nullptr, QString(), this); // Non-singleton constructor
    return m_defaults;
}

void GlobalConfig::bindAppearanceTokens() {
    if (m_tokensBound)
        return;

    auto* tokens = TokenConfig::instance();
    if (!tokens) {
        qCDebug(lcConfig) << "GlobalConfig::bindAppearanceTokens: TokenConfig not yet available";
        return;
    }

    qCDebug(lcConfig) << "GlobalConfig::bindAppearanceTokens: binding appearance to token values";
    auto* tokenAppearance = tokens->appearance();
    m_appearance->rounding()->bindTokens(tokenAppearance->rounding());
    m_appearance->spacing()->bindTokens(tokenAppearance->spacing());
    m_appearance->padding()->bindTokens(tokenAppearance->padding());
    m_appearance->font()->size()->bindTokens(tokenAppearance->fontSize());
    m_appearance->anim()->durations()->bindTokens(tokenAppearance->animDurations());
    m_tokensBound = true;
}

GlobalConfig* GlobalConfig::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    auto* config = new GlobalConfig(engine);

    // Ensure TokenConfig is created — appearance computed properties depend on token binding.
    if (!TokenConfig::instance())
        TokenConfig::create(engine, jsEngine);

    // Bind now that both singletons exist
    config->bindAppearanceTokens();

    return config;
}

void GlobalConfig::save() {
    saveToFile();
}

void GlobalConfig::reload() {
    reloadFromFile();
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

Config* Config::qmlAttachedProperties(QObject* object) {
    return new Config(ConfigScope::find(object), object);
}

} // namespace caelestia::config
