#pragma once

#include <qqmlintegration.h>
#include <qquickitem.h>

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
    // advanced is NOT a CONFIG_SUBOBJECT — it has its own file backend
    Q_PROPERTY(AdvancedConfig* advanced READ advanced CONSTANT)

public:
    static GlobalConfig* instance();
    static GlobalConfig* create(QQmlEngine*, QJSEngine*);

    [[nodiscard]] AdvancedConfig* advanced() const { return m_advanced; }

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

private:
    explicit GlobalConfig(QObject* parent = nullptr);

    AdvancedConfig* m_advanced = nullptr;
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
