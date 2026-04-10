#include "config.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qlogging.h>
#include <qstandardpaths.h>

namespace caelestia::config {

static GlobalConfig* s_instance = nullptr;

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
    s_instance = this;

    m_configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
                   QStringLiteral("/caelestia/shell.json");

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &GlobalConfig::writeToFile);

    m_cooldownTimer.setSingleShot(true);
    m_cooldownTimer.setInterval(2000);
    connect(&m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
        emit recentlySavedChanged();
    });

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &GlobalConfig::onFileChanged);

    reload();

    if (QFile::exists(m_configPath)) {
        m_watcher.addPath(m_configPath);
    }
}

GlobalConfig* GlobalConfig::instance() {
    return s_instance;
}

bool GlobalConfig::recentlySaved() const {
    return m_recentlySaved;
}

void GlobalConfig::save() {
    m_saveTimer.start();
    m_recentlySaved = true;
    emit recentlySavedChanged();
    m_cooldownTimer.start();
}

void GlobalConfig::reload() {
    QFile file(m_configPath);

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Config: failed to open" << m_configPath;
        return;
    }

    load(file.readAll());
}

void GlobalConfig::load(const QByteArray& contents) {
    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(contents, &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "Config: failed to parse JSON:" << error.errorString();
        return;
    }

    loadFromJson(doc.object());
}

void GlobalConfig::onFileChanged() {
    if (!m_watcher.files().contains(m_configPath)) {
        m_watcher.addPath(m_configPath);
    }

    if (!m_recentlySaved) {
        reload();
    }
}

void GlobalConfig::writeToFile() {
    QDir().mkpath(QFileInfo(m_configPath).absolutePath());

    QFile file(m_configPath);

    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "Config: failed to write" << m_configPath;
        return;
    }

    file.write(QJsonDocument(toJsonObject()).toJson(QJsonDocument::Indented));
}

// Config

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
