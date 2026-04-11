#include "config.hpp"
#include "configscope.hpp"

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

Config::Config(ConfigScope* scope, QObject* parent)
    : QObject(parent)
    , m_scope(scope) {}

Config* Config::qmlAttachedProperties(QObject* object) {
    return new Config(ConfigScope::find(object), object);
}

} // namespace caelestia::config
