#pragma once

#include <qfilesystemwatcher.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qtimer.h>

#include "advancedconfig.hpp"
#include "appearanceconfig.hpp"
#include "backgroundconfig.hpp"
#include "barconfig.hpp"
#include "borderconfig.hpp"
#include "controlcenterconfig.hpp"
#include "dashboardconfig.hpp"
#include "generalconfig.hpp"
#include "launcherconfig.hpp"
#include "lockconfig.hpp"
#include "notifsconfig.hpp"
#include "osdconfig.hpp"
#include "serviceconfig.hpp"
#include "sessionconfig.hpp"
#include "sidebarconfig.hpp"
#include "userpaths.hpp"
#include "utilitiesconfig.hpp"
#include "winfoconfig.hpp"

namespace caelestia::config {

class GlobalConfig : public ConfigObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    CONFIG_SUBOBJECT(AppearanceConfig, appearance)
    CONFIG_SUBOBJECT(GeneralConfig, general)
    CONFIG_SUBOBJECT(BackgroundConfig, background)
    CONFIG_SUBOBJECT(BarConfig, bar)
    CONFIG_SUBOBJECT(BorderConfig, border)
    CONFIG_SUBOBJECT(DashboardConfig, dashboard)
    CONFIG_SUBOBJECT(ControlCenterConfig, controlCenter)
    CONFIG_SUBOBJECT(LauncherConfig, launcher)
    CONFIG_SUBOBJECT(NotifsConfig, notifs)
    CONFIG_SUBOBJECT(OsdConfig, osd)
    CONFIG_SUBOBJECT(SessionConfig, session)
    CONFIG_SUBOBJECT(WInfoConfig, winfo)
    CONFIG_SUBOBJECT(LockConfig, lock)
    CONFIG_SUBOBJECT(UtilitiesConfig, utilities)
    CONFIG_SUBOBJECT(SidebarConfig, sidebar)
    CONFIG_SUBOBJECT(ServiceConfig, services)
    CONFIG_SUBOBJECT(UserPaths, paths)
    CONFIG_SUBOBJECT(AdvancedConfig, advanced)

    Q_PROPERTY(bool recentlySaved READ recentlySaved NOTIFY recentlySavedChanged)

public:
    explicit GlobalConfig(QObject* parent = nullptr);

    static GlobalConfig* instance();

    [[nodiscard]] bool recentlySaved() const;

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

signals:
    void recentlySavedChanged();

private:
    void load(const QByteArray& contents);
    void onFileChanged();
    void writeToFile();

    bool m_recentlySaved = false;
    QString m_configPath;
    QFileSystemWatcher m_watcher;
    QTimer m_saveTimer;
    QTimer m_cooldownTimer;
};

class Config : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(Config)

public:
    explicit Config(QQuickItem* parent = nullptr);

    static Config* qmlAttachedProperties(QObject* object);
};

} // namespace caelestia::config
