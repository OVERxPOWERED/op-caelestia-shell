#include "anim.hpp"
#include "appearanceconfig.hpp"
#include "tokens.hpp"

#include <qpoint.h>

namespace caelestia::config {

AnimTokens::AnimTokens(QObject* parent)
    : QObject(parent) {}

QEasingCurve AnimTokens::buildCurve(const QList<qreal>& points) {
    QEasingCurve curve(QEasingCurve::BezierSpline);

    // Points come in pairs of (x, y) forming cubic bezier segments.
    // Each segment needs 3 control points: c1, c2, endPoint.
    // So 6 values per segment: c1x, c1y, c2x, c2y, endX, endY.
    for (int i = 0; i + 5 < points.size(); i += 6) {
        QPointF c1(points[i], points[i + 1]);
        QPointF c2(points[i + 2], points[i + 3]);
        QPointF end(points[i + 4], points[i + 5]);
        curve.addCubicBezierSegment(c1, c2, end);
    }

    return curve;
}

void AnimTokens::rebuildCurves() {
    if (!m_curves)
        return;

    m_emphasized = buildCurve(m_curves->emphasized());
    m_emphasizedAccel = buildCurve(m_curves->emphasizedAccel());
    m_emphasizedDecel = buildCurve(m_curves->emphasizedDecel());
    m_standard = buildCurve(m_curves->standard());
    m_standardAccel = buildCurve(m_curves->standardAccel());
    m_standardDecel = buildCurve(m_curves->standardDecel());
    m_expressiveFastSpatial = buildCurve(m_curves->expressiveFastSpatial());
    m_expressiveDefaultSpatial = buildCurve(m_curves->expressiveDefaultSpatial());
    m_expressiveSlowSpatial = buildCurve(m_curves->expressiveSlowSpatial());

    emit curvesChanged();
}

void AnimTokens::bindCurves(AnimCurves* curves) {
    m_curves = curves;

    // Rebuild when any curve control points change
    connect(curves, &AnimCurves::propertiesChanged, this, &AnimTokens::rebuildCurves);

    rebuildCurves();
}

void AnimTokens::bindDurations(AnimDurations* durations) {
    if (m_durations == durations)
        return;

    m_durations = durations;
    emit durationsChanged();
}

} // namespace caelestia::config
