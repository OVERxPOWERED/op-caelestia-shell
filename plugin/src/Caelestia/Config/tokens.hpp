#pragma once

#include "configobject.hpp"

#include <qlist.h>
#include <qqmlengine.h>

namespace caelestia::config {

class ConfigScope;

class AnimCurves : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QList<qreal>, emphasized)
    CONFIG_PROPERTY(QList<qreal>, emphasizedAccel)
    CONFIG_PROPERTY(QList<qreal>, emphasizedDecel)
    CONFIG_PROPERTY(QList<qreal>, standard)
    CONFIG_PROPERTY(QList<qreal>, standardAccel)
    CONFIG_PROPERTY(QList<qreal>, standardDecel)
    CONFIG_PROPERTY(QList<qreal>, expressiveFastSpatial)
    CONFIG_PROPERTY(QList<qreal>, expressiveDefaultSpatial)
    CONFIG_PROPERTY(QList<qreal>, expressiveSlowSpatial)

public:
    explicit AnimCurves(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_emphasized({ 0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1 })
        , m_emphasizedAccel({ 0.3, 0, 0.8, 0.15, 1, 1 })
        , m_emphasizedDecel({ 0.05, 0.7, 0.1, 1, 1, 1 })
        , m_standard({ 0.2, 0, 0, 1, 1, 1 })
        , m_standardAccel({ 0.3, 0, 1, 1, 1, 1 })
        , m_standardDecel({ 0, 0, 0, 1, 1, 1 })
        , m_expressiveFastSpatial({ 0.42, 1.67, 0.21, 0.9, 1, 1 })
        , m_expressiveDefaultSpatial({ 0.38, 1.21, 0.22, 1, 1, 1 })
        , m_expressiveSlowSpatial({ 0.39, 1.29, 0.35, 0.98, 1, 1 }) {}
};

class RoundingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 12)
    CONFIG_PROPERTY(int, normal, 17)
    CONFIG_PROPERTY(int, large, 25)
    CONFIG_PROPERTY(int, full, 1000)

public:
    explicit RoundingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SpacingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 7)
    CONFIG_PROPERTY(int, smaller, 10)
    CONFIG_PROPERTY(int, normal, 12)
    CONFIG_PROPERTY(int, larger, 15)
    CONFIG_PROPERTY(int, large, 20)

public:
    explicit SpacingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class PaddingTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 5)
    CONFIG_PROPERTY(int, smaller, 7)
    CONFIG_PROPERTY(int, normal, 10)
    CONFIG_PROPERTY(int, larger, 12)
    CONFIG_PROPERTY(int, large, 15)

public:
    explicit PaddingTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class FontSizeTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 11)
    CONFIG_PROPERTY(int, smaller, 12)
    CONFIG_PROPERTY(int, normal, 13)
    CONFIG_PROPERTY(int, larger, 15)
    CONFIG_PROPERTY(int, large, 18)
    CONFIG_PROPERTY(int, extraLarge, 28)

public:
    explicit FontSizeTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AnimDurationTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, small, 200)
    CONFIG_PROPERTY(int, normal, 400)
    CONFIG_PROPERTY(int, large, 600)
    CONFIG_PROPERTY(int, extraLarge, 1000)
    CONFIG_PROPERTY(int, expressiveFastSpatial, 350)
    CONFIG_PROPERTY(int, expressiveDefaultSpatial, 500)
    CONFIG_PROPERTY(int, expressiveSlowSpatial, 650)

public:
    explicit AnimDurationTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AppearanceTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(AnimCurves, curves)
    CONFIG_SUBOBJECT(RoundingTokens, rounding)
    CONFIG_SUBOBJECT(SpacingTokens, spacing)
    CONFIG_SUBOBJECT(PaddingTokens, padding)
    CONFIG_SUBOBJECT(FontSizeTokens, fontSize)
    CONFIG_SUBOBJECT(AnimDurationTokens, animDurations)

public:
    explicit AppearanceTokens(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_curves(new AnimCurves(this))
        , m_rounding(new RoundingTokens(this))
        , m_spacing(new SpacingTokens(this))
        , m_padding(new PaddingTokens(this))
        , m_fontSize(new FontSizeTokens(this))
        , m_animDurations(new AnimDurationTokens(this)) {}
};

class BarTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, innerWidth, 40)
    CONFIG_PROPERTY(int, windowPreviewSize, 400)
    CONFIG_PROPERTY(int, trayMenuWidth, 300)
    CONFIG_PROPERTY(int, batteryWidth, 250)
    CONFIG_PROPERTY(int, networkWidth, 320)
    CONFIG_PROPERTY(int, kbLayoutWidth, 320)

public:
    explicit BarTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DashboardTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showDashboard, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showPerformance, true)
    CONFIG_PROPERTY(bool, showWeather, true)
    CONFIG_PROPERTY(int, tabIndicatorHeight, 3)
    CONFIG_PROPERTY(int, tabIndicatorSpacing, 5)
    CONFIG_PROPERTY(int, infoWidth, 200)
    CONFIG_PROPERTY(int, infoIconSize, 25)
    CONFIG_PROPERTY(int, dateTimeWidth, 110)
    CONFIG_PROPERTY(int, mediaWidth, 200)
    CONFIG_PROPERTY(int, mediaProgressSweep, 180)
    CONFIG_PROPERTY(int, mediaProgressThickness, 8)
    CONFIG_PROPERTY(int, resourceProgressThickness, 10)
    CONFIG_PROPERTY(int, weatherWidth, 250)
    CONFIG_PROPERTY(int, mediaCoverArtSize, 150)
    CONFIG_PROPERTY(int, mediaVisualiserSize, 80)
    CONFIG_PROPERTY(int, resourceSize, 200)

public:
    explicit DashboardTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LauncherTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, itemWidth, 600)
    CONFIG_PROPERTY(int, itemHeight, 57)
    CONFIG_PROPERTY(int, wallpaperWidth, 280)
    CONFIG_PROPERTY(int, wallpaperHeight, 200)

public:
    explicit LauncherTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class NotifsTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 400)
    CONFIG_PROPERTY(int, image, 41)
    CONFIG_PROPERTY(int, badge, 20)

public:
    explicit NotifsTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class OsdTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, sliderWidth, 30)
    CONFIG_PROPERTY(int, sliderHeight, 150)

public:
    explicit OsdTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, button, 80)

public:
    explicit SessionTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 430)

public:
    explicit SidebarTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, width, 430)
    CONFIG_PROPERTY(int, toastWidth, 430)

public:
    explicit UtilitiesTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LockTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)
    CONFIG_PROPERTY(int, centerWidth, 600)

public:
    explicit LockTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WInfoTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, detailsWidth, 500)

public:
    explicit WInfoTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class ControlCenterTokens : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)

public:
    explicit ControlCenterTokens(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class TokenConfig : public ConfigObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    CONFIG_SUBOBJECT(AppearanceTokens, appearance)
    CONFIG_SUBOBJECT(BarTokens, bar)
    CONFIG_SUBOBJECT(DashboardTokens, dashboard)
    CONFIG_SUBOBJECT(LauncherTokens, launcher)
    CONFIG_SUBOBJECT(NotifsTokens, notifs)
    CONFIG_SUBOBJECT(OsdTokens, osd)
    CONFIG_SUBOBJECT(SessionTokens, session)
    CONFIG_SUBOBJECT(SidebarTokens, sidebar)
    CONFIG_SUBOBJECT(UtilitiesTokens, utilities)
    CONFIG_SUBOBJECT(LockTokens, lock)
    CONFIG_SUBOBJECT(WInfoTokens, winfo)
    CONFIG_SUBOBJECT(ControlCenterTokens, controlCenter)

public:
    static TokenConfig* instance();
    [[nodiscard]] Q_INVOKABLE TokenConfig* defaults();
    static TokenConfig* create(QQmlEngine*, QJSEngine*);

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

    ~TokenConfig() override;

private:
    friend class MonitorConfigManager;
    explicit TokenConfig(QObject* parent = nullptr);
    explicit TokenConfig(TokenConfig* fallback, const QString& filePath, QObject* parent = nullptr);

    TokenConfig* m_defaults = nullptr;
};

class Tokens : public QObject {
    Q_OBJECT
    Q_MOC_INCLUDE("configscope.hpp")
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Tokens)

    Q_PROPERTY(caelestia::config::ConfigScope* scope READ scope NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceTokens* appearance READ appearance NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::BarTokens* bar READ bar NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::DashboardTokens* dashboard READ dashboard NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::LauncherTokens* launcher READ launcher NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::NotifsTokens* notifs READ notifs NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::OsdTokens* osd READ osd NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SessionTokens* session READ session NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SidebarTokens* sidebar READ sidebar NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::UtilitiesTokens* utilities READ utilities NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::LockTokens* lock READ lock NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::WInfoTokens* winfo READ winfo NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::ControlCenterTokens* controlCenter READ controlCenter NOTIFY sourceChanged)

public:
    explicit Tokens(ConfigScope* scope, QObject* parent = nullptr);

    [[nodiscard]] ConfigScope* scope() const { return m_scope; }

    [[nodiscard]] const AppearanceTokens* appearance() const;
    [[nodiscard]] const BarTokens* bar() const;
    [[nodiscard]] const DashboardTokens* dashboard() const;
    [[nodiscard]] const LauncherTokens* launcher() const;
    [[nodiscard]] const NotifsTokens* notifs() const;
    [[nodiscard]] const OsdTokens* osd() const;
    [[nodiscard]] const SessionTokens* session() const;
    [[nodiscard]] const SidebarTokens* sidebar() const;
    [[nodiscard]] const UtilitiesTokens* utilities() const;
    [[nodiscard]] const LockTokens* lock() const;
    [[nodiscard]] const WInfoTokens* winfo() const;
    [[nodiscard]] const ControlCenterTokens* controlCenter() const;

    static Tokens* qmlAttachedProperties(QObject* object);

    Q_SIGNAL void sourceChanged();

private:
    void connectScope();

    ConfigScope* m_scope;
};

} // namespace caelestia::config
