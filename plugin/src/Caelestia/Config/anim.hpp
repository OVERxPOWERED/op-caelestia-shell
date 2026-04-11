#pragma once

#include <qeasingcurve.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::config {

class AnimCurves;
class AnimDurations;
class ConfigScope;

class AnimTokens : public QObject {
    Q_OBJECT
    Q_MOC_INCLUDE("appearanceconfig.hpp")
    QML_ANONYMOUS

    Q_PROPERTY(QEasingCurve emphasized READ emphasized NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedAccel READ emphasizedAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedDecel READ emphasizedDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standard READ standard NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardAccel READ standardAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardDecel READ standardDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveFastSpatial READ expressiveFastSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveDefaultSpatial READ expressiveDefaultSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveSlowSpatial READ expressiveSlowSpatial NOTIFY curvesChanged)

    Q_PROPERTY(caelestia::config::AnimDurations* durations READ durations NOTIFY durationsChanged)

public:
    explicit AnimTokens(QObject* parent = nullptr);

    void bindCurves(AnimCurves* curves);
    void bindDurations(AnimDurations* durations);

    [[nodiscard]] QEasingCurve emphasized() const { return m_emphasized; }

    [[nodiscard]] QEasingCurve emphasizedAccel() const { return m_emphasizedAccel; }

    [[nodiscard]] QEasingCurve emphasizedDecel() const { return m_emphasizedDecel; }

    [[nodiscard]] QEasingCurve standard() const { return m_standard; }

    [[nodiscard]] QEasingCurve standardAccel() const { return m_standardAccel; }

    [[nodiscard]] QEasingCurve standardDecel() const { return m_standardDecel; }

    [[nodiscard]] QEasingCurve expressiveFastSpatial() const { return m_expressiveFastSpatial; }

    [[nodiscard]] QEasingCurve expressiveDefaultSpatial() const { return m_expressiveDefaultSpatial; }

    [[nodiscard]] QEasingCurve expressiveSlowSpatial() const { return m_expressiveSlowSpatial; }

    [[nodiscard]] AnimDurations* durations() const { return m_durations; }

signals:
    void curvesChanged();
    void durationsChanged();

private:
    void rebuildCurves();
    static QEasingCurve buildCurve(const QList<qreal>& points);

    AnimCurves* m_curves = nullptr;
    AnimDurations* m_durations = nullptr;

    QEasingCurve m_emphasized;
    QEasingCurve m_emphasizedAccel;
    QEasingCurve m_emphasizedDecel;
    QEasingCurve m_standard;
    QEasingCurve m_standardAccel;
    QEasingCurve m_standardDecel;
    QEasingCurve m_expressiveFastSpatial;
    QEasingCurve m_expressiveDefaultSpatial;
    QEasingCurve m_expressiveSlowSpatial;
};

} // namespace caelestia::config
