#include "config.hpp"

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
    , m_paths(new UserPaths(this))
    , m_advanced(new AdvancedConfig(this)) {
    // Set global instance
    s_instance = this;

    // Bind token base values from advanced config to appearance computed properties
    auto* adv = m_advanced->appearance();
    m_appearance->rounding()->bindTokens(adv->rounding());
    m_appearance->spacing()->bindTokens(adv->spacing());
    m_appearance->padding()->bindTokens(adv->padding());
    m_appearance->font()->size()->bindTokens(adv->fontSize());
    m_appearance->anim()->durations()->bindTokens(adv->animDurations());

    // Each has its own file backend
    setupFileBackend(configDir() + QStringLiteral("shell.json"));
    m_advanced->setupFileBackend(configDir() + QStringLiteral("advanced.json"));
}

GlobalConfig::~GlobalConfig() {
    // Clear global instance
    s_instance = nullptr;
}

GlobalConfig* GlobalConfig::instance() {
    return s_instance;
}

GlobalConfig* GlobalConfig::create(QQmlEngine* engine, QJSEngine*) {
    auto* config = new GlobalConfig(engine);
    return config;
}

void GlobalConfig::save() {
    saveToFile();
}

void GlobalConfig::reload() {
    reloadFromFile();
}

// Config (attached type)

Config::Config(QQuickItem* parent)
    : QQuickItem(parent) {}

Config* Config::qmlAttachedProperties(QObject* object) {
    auto* item = qobject_cast<QQuickItem*>(object);

    while (item) {
        if (auto* config = qobject_cast<Config*>(item))
            return config;
        item = item->parentItem();
    }

    return nullptr;
}

} // namespace caelestia::config
