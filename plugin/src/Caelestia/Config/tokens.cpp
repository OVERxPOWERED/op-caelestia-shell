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
    : ConfigObject(parent)
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

    // Bind token base values to GlobalConfig appearance computed properties
    if (auto* global = GlobalConfig::instance()) {
        auto* appearanceConfig = global->appearance();
        appearanceConfig->rounding()->bindTokens(m_appearance->rounding());
        appearanceConfig->spacing()->bindTokens(m_appearance->spacing());
        appearanceConfig->padding()->bindTokens(m_appearance->padding());
        appearanceConfig->font()->size()->bindTokens(m_appearance->fontSize());
        appearanceConfig->anim()->durations()->bindTokens(m_appearance->animDurations());
    }

    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));
}

TokenConfig::~TokenConfig() {
    s_instance = nullptr;
}

TokenConfig* TokenConfig::instance() {
    return s_instance;
}

TokenConfig* TokenConfig::create(QQmlEngine* engine, QJSEngine*) {
    return new TokenConfig(engine);
}

void TokenConfig::save() {
    saveToFile();
}

void TokenConfig::reload() {
    reloadFromFile();
}

// Tokens (attached type)

Tokens::Tokens(ConfigScope* scope, QObject* parent)
    : QObject(parent)
    , m_scope(scope) {}

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    return new Tokens(ConfigScope::find(object), object);
}

} // namespace caelestia::config
