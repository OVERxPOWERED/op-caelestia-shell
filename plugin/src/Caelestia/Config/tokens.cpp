#include "tokens.hpp"
#include "config.hpp"
#include "configscope.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

TokenConfig* s_instance = nullptr;

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

TokenConfig::TokenConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_bar(new BarTokens(this))
    , m_dashboard(new DashboardTokens(this))
    , m_launcher(new LauncherTokens(this))
    , m_notifs(new NotifsTokens(this))
    , m_osd(new OsdTokens(this))
    , m_session(new SessionTokens(this))
    , m_sidebar(new SidebarTokens(this))
    , m_utilities(new UtilitiesTokens(this))
    , m_lock(new LockTokens(this))
    , m_winfo(new WInfoTokens(this))
    , m_controlCenter(new ControlCenterTokens(this)) {
    s_instance = this;

    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));

    // If GlobalConfig was created before us, trigger its binding
    if (auto* global = GlobalConfig::instance())
        global->bindAppearanceTokens();
}

TokenConfig::TokenConfig(TokenConfig* fallback, const QString& filePath, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_bar(new BarTokens(this))
    , m_dashboard(new DashboardTokens(this))
    , m_launcher(new LauncherTokens(this))
    , m_notifs(new NotifsTokens(this))
    , m_osd(new OsdTokens(this))
    , m_session(new SessionTokens(this))
    , m_sidebar(new SidebarTokens(this))
    , m_utilities(new UtilitiesTokens(this))
    , m_lock(new LockTokens(this))
    , m_winfo(new WInfoTokens(this))
    , m_controlCenter(new ControlCenterTokens(this)) {
    setSparse(true);
    if (!filePath.isEmpty())
        setupFileBackend(filePath);
    if (fallback)
        syncFromGlobal(fallback);
}

TokenConfig::~TokenConfig() {
    if (s_instance == this)
        s_instance = nullptr;
}

TokenConfig* TokenConfig::instance() {
    return s_instance;
}

TokenConfig* TokenConfig::defaults() {
    if (!m_defaults)
        m_defaults = new TokenConfig(nullptr, QString(), this); // Non-singleton constructor
    return m_defaults;
}

TokenConfig* TokenConfig::create(QQmlEngine* engine, QJSEngine*) {
    return new TokenConfig(engine);
}

// Tokens (attached type)

Tokens::Tokens(ConfigScope* scope, QObject* parent)
    : QObject(parent)
    , m_scope(scope) {
    connectScope();
}

void Tokens::connectScope() {
    if (!m_scope)
        return;
    connect(m_scope, &ConfigScope::tokensChanged, this, &Tokens::sourceChanged);
    connect(m_scope, &ConfigScope::configChanged, this, &Tokens::sourceChanged);
}

#define TOKENS_ATTACHED_GETTER(Type, name)                                                                             \
    const Type* Tokens::name() const {                                                                                 \
        if (m_scope && m_scope->tokens())                                                                              \
            return m_scope->tokens()->name();                                                                          \
        auto* global = TokenConfig::instance();                                                                        \
        return global ? global->name() : nullptr;                                                                      \
    }

TOKENS_ATTACHED_GETTER(AppearanceTokens, appearance)
TOKENS_ATTACHED_GETTER(BarTokens, bar)
TOKENS_ATTACHED_GETTER(DashboardTokens, dashboard)
TOKENS_ATTACHED_GETTER(LauncherTokens, launcher)
TOKENS_ATTACHED_GETTER(NotifsTokens, notifs)
TOKENS_ATTACHED_GETTER(OsdTokens, osd)
TOKENS_ATTACHED_GETTER(SessionTokens, session)
TOKENS_ATTACHED_GETTER(SidebarTokens, sidebar)
TOKENS_ATTACHED_GETTER(UtilitiesTokens, utilities)
TOKENS_ATTACHED_GETTER(LockTokens, lock)
TOKENS_ATTACHED_GETTER(WInfoTokens, winfo)
TOKENS_ATTACHED_GETTER(ControlCenterTokens, controlCenter)

#undef TOKENS_ATTACHED_GETTER

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    // Ensure TokenConfig singleton is created before any attached property access
    if (!TokenConfig::instance()) {
        if (auto* engine = qmlEngine(object))
            engine->singletonInstance<TokenConfig*>("Caelestia.Config", "TokenConfig");
    }
    return new Tokens(ConfigScope::find(object), object);
}

} // namespace caelestia::config
