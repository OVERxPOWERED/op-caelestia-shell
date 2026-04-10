#pragma once

#include "configobject.hpp"

#include <qlist.h>

namespace caelestia::config {

class AnimCurves : public ConfigObject {
    Q_OBJECT
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

class AdvancedAppearance : public ConfigObject {
    Q_OBJECT
    CONFIG_SUBOBJECT(AnimCurves, curves)

public:
    explicit AdvancedAppearance(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_curves(new AnimCurves(this)) {}
};

class BarSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, innerWidth, 40)
    CONFIG_PROPERTY(int, windowPreviewSize, 400)
    CONFIG_PROPERTY(int, trayMenuWidth, 300)
    CONFIG_PROPERTY(int, batteryWidth, 250)
    CONFIG_PROPERTY(int, networkWidth, 320)
    CONFIG_PROPERTY(int, kbLayoutWidth, 320)

public:
    explicit BarSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AdvancedDashboard : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(bool, showDashboard, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showPerformance, true)
    CONFIG_PROPERTY(bool, showWeather, true)

    Q_PROPERTY(int tabIndicatorHeight READ tabIndicatorHeight CONSTANT)
    Q_PROPERTY(int tabIndicatorSpacing READ tabIndicatorSpacing CONSTANT)
    Q_PROPERTY(int infoWidth READ infoWidth CONSTANT)
    Q_PROPERTY(int infoIconSize READ infoIconSize CONSTANT)
    Q_PROPERTY(int dateTimeWidth READ dateTimeWidth CONSTANT)
    Q_PROPERTY(int mediaWidth READ mediaWidth CONSTANT)
    Q_PROPERTY(int mediaProgressSweep READ mediaProgressSweep CONSTANT)
    Q_PROPERTY(int mediaProgressThickness READ mediaProgressThickness CONSTANT)
    Q_PROPERTY(int resourceProgessThickness READ resourceProgessThickness CONSTANT)
    Q_PROPERTY(int weatherWidth READ weatherWidth CONSTANT)
    Q_PROPERTY(int mediaCoverArtSize READ mediaCoverArtSize CONSTANT)
    Q_PROPERTY(int mediaVisualiserSize READ mediaVisualiserSize CONSTANT)
    Q_PROPERTY(int resourceSize READ resourceSize CONSTANT)

public:
    explicit AdvancedDashboard(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] static int tabIndicatorHeight() { return 3; }

    [[nodiscard]] static int tabIndicatorSpacing() { return 5; }

    [[nodiscard]] static int infoWidth() { return 200; }

    [[nodiscard]] static int infoIconSize() { return 25; }

    [[nodiscard]] static int dateTimeWidth() { return 110; }

    [[nodiscard]] static int mediaWidth() { return 200; }

    [[nodiscard]] static int mediaProgressSweep() { return 180; }

    [[nodiscard]] static int mediaProgressThickness() { return 8; }

    [[nodiscard]] static int resourceProgessThickness() { return 10; }

    [[nodiscard]] static int weatherWidth() { return 250; }

    [[nodiscard]] static int mediaCoverArtSize() { return 150; }

    [[nodiscard]] static int mediaVisualiserSize() { return 80; }

    [[nodiscard]] static int resourceSize() { return 200; }
};

class LauncherSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, itemWidth, 600)
    CONFIG_PROPERTY(int, itemHeight, 57)
    CONFIG_PROPERTY(int, wallpaperWidth, 280)
    CONFIG_PROPERTY(int, wallpaperHeight, 200)

public:
    explicit LauncherSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class NotifsSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, width, 400)
    CONFIG_PROPERTY(int, image, 41)
    CONFIG_PROPERTY(int, badge, 20)

public:
    explicit NotifsSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class OsdSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, sliderWidth, 30)
    CONFIG_PROPERTY(int, sliderHeight, 150)

public:
    explicit OsdSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, button, 80)

public:
    explicit SessionSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SidebarSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, width, 430)

public:
    explicit SidebarSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(int, width, 430)
    CONFIG_PROPERTY(int, toastWidth, 430)

public:
    explicit UtilitiesSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LockSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)
    CONFIG_PROPERTY(int, centerWidth, 600)

public:
    explicit LockSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class WInfoSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, detailsWidth, 500)

public:
    explicit WInfoSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class ControlCenterSizes : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, heightMult, 0.7)
    CONFIG_PROPERTY(qreal, ratio, 16.0 / 9.0)

public:
    explicit ControlCenterSizes(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AdvancedConfig : public ConfigObject {
    Q_OBJECT
    CONFIG_SUBOBJECT(AdvancedAppearance, appearance)
    CONFIG_SUBOBJECT(BarSizes, bar)
    CONFIG_SUBOBJECT(AdvancedDashboard, dashboard)
    CONFIG_SUBOBJECT(LauncherSizes, launcher)
    CONFIG_SUBOBJECT(NotifsSizes, notifs)
    CONFIG_SUBOBJECT(OsdSizes, osd)
    CONFIG_SUBOBJECT(SessionSizes, session)
    CONFIG_SUBOBJECT(SidebarSizes, sidebar)
    CONFIG_SUBOBJECT(UtilitiesSizes, utilities)
    CONFIG_SUBOBJECT(LockSizes, lock)
    CONFIG_SUBOBJECT(WInfoSizes, winfo)
    CONFIG_SUBOBJECT(ControlCenterSizes, controlCenter)

public:
    explicit AdvancedConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_appearance(new AdvancedAppearance(this))
        , m_bar(new BarSizes(this))
        , m_dashboard(new AdvancedDashboard(this))
        , m_launcher(new LauncherSizes(this))
        , m_notifs(new NotifsSizes(this))
        , m_osd(new OsdSizes(this))
        , m_session(new SessionSizes(this))
        , m_sidebar(new SidebarSizes(this))
        , m_utilities(new UtilitiesSizes(this))
        , m_lock(new LockSizes(this))
        , m_winfo(new WInfoSizes(this))
        , m_controlCenter(new ControlCenterSizes(this)) {}
};

} // namespace caelestia::config
