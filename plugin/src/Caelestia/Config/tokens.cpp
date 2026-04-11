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
    connect(m_scope, &ConfigScope::configChanged, this, &Tokens::sourceChanged);
}

// Resolve appearance from per-monitor GlobalConfig overlay or global GlobalConfig
static const AppearanceConfig* resolveAppearance(ConfigScope* scope) {
    if (scope && scope->config())
        return scope->config()->appearance();
    auto* global = GlobalConfig::instance();
    return global ? global->appearance() : nullptr;
}

const AppearanceRounding* Tokens::rounding() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->rounding() : nullptr;
}

const AppearanceSpacing* Tokens::spacing() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->spacing() : nullptr;
}

const AppearancePadding* Tokens::padding() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->padding() : nullptr;
}

const AppearanceFont* Tokens::font() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->font() : nullptr;
}

const AppearanceAnim* Tokens::anim() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->anim() : nullptr;
}

const AppearanceTransparency* Tokens::transparency() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->transparency() : nullptr;
}

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    // Ensure GlobalConfig singleton is created before any attached property access
    if (!GlobalConfig::instance()) {
        if (auto* engine = qmlEngine(object))
            engine->singletonInstance<GlobalConfig*>("Caelestia.Config", "GlobalConfig");
    }
    return new Tokens(ConfigScope::find(object), object);
}

} // namespace caelestia::config
