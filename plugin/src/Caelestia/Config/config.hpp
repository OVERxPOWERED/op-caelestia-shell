#pragma once

#include <qqmlengine.h>

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

public:
    static GlobalConfig* instance();
    static GlobalConfig* create(QQmlEngine*, QJSEngine*);

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

    ~GlobalConfig() override;

    void bindAppearanceTokens();

private:
    friend class MonitorConfigManager;
    explicit GlobalConfig(QObject* parent = nullptr);
    explicit GlobalConfig(GlobalConfig* fallback, const QString& filePath, QObject* parent);

    bool m_tokensBound = false;
};

class ConfigScope;

class Config : public QObject {
    Q_OBJECT
    Q_MOC_INCLUDE("configscope.hpp")
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Config)

    Q_PROPERTY(ConfigScope* scope READ scope NOTIFY sourceChanged)
    Q_PROPERTY(const AppearanceConfig* appearance READ appearance NOTIFY sourceChanged)
    Q_PROPERTY(const GeneralConfig* general READ general NOTIFY sourceChanged)
    Q_PROPERTY(const BackgroundConfig* background READ background NOTIFY sourceChanged)
    Q_PROPERTY(const BarConfig* bar READ bar NOTIFY sourceChanged)
    Q_PROPERTY(const BorderConfig* border READ border NOTIFY sourceChanged)
    Q_PROPERTY(const DashboardConfig* dashboard READ dashboard NOTIFY sourceChanged)
    Q_PROPERTY(const ControlCenterConfig* controlCenter READ controlCenter NOTIFY sourceChanged)
    Q_PROPERTY(const LauncherConfig* launcher READ launcher NOTIFY sourceChanged)
    Q_PROPERTY(const NotifsConfig* notifs READ notifs NOTIFY sourceChanged)
    Q_PROPERTY(const OsdConfig* osd READ osd NOTIFY sourceChanged)
    Q_PROPERTY(const SessionConfig* session READ session NOTIFY sourceChanged)
    Q_PROPERTY(const WInfoConfig* winfo READ winfo NOTIFY sourceChanged)
    Q_PROPERTY(const LockConfig* lock READ lock NOTIFY sourceChanged)
    Q_PROPERTY(const UtilitiesConfig* utilities READ utilities NOTIFY sourceChanged)
    Q_PROPERTY(const SidebarConfig* sidebar READ sidebar NOTIFY sourceChanged)
    Q_PROPERTY(const ServiceConfig* services READ services NOTIFY sourceChanged)
    Q_PROPERTY(const UserPaths* paths READ paths NOTIFY sourceChanged)

public:
    explicit Config(ConfigScope* scope, QObject* parent = nullptr);

    [[nodiscard]] ConfigScope* scope() const { return m_scope; }

    [[nodiscard]] const AppearanceConfig* appearance() const;
    [[nodiscard]] const GeneralConfig* general() const;
    [[nodiscard]] const BackgroundConfig* background() const;
    [[nodiscard]] const BarConfig* bar() const;
    [[nodiscard]] const BorderConfig* border() const;
    [[nodiscard]] const DashboardConfig* dashboard() const;
    [[nodiscard]] const ControlCenterConfig* controlCenter() const;
    [[nodiscard]] const LauncherConfig* launcher() const;
    [[nodiscard]] const NotifsConfig* notifs() const;
    [[nodiscard]] const OsdConfig* osd() const;
    [[nodiscard]] const SessionConfig* session() const;
    [[nodiscard]] const WInfoConfig* winfo() const;
    [[nodiscard]] const LockConfig* lock() const;
    [[nodiscard]] const UtilitiesConfig* utilities() const;
    [[nodiscard]] const SidebarConfig* sidebar() const;
    [[nodiscard]] const ServiceConfig* services() const;
    [[nodiscard]] const UserPaths* paths() const;

    static Config* qmlAttachedProperties(QObject* object);

    Q_SIGNAL void sourceChanged();

private:
    void connectScope();

    ConfigScope* m_scope;
};

} // namespace caelestia::config
