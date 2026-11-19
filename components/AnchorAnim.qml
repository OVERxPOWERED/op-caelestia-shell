import QtQuick
import Caelestia.Config

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        if (type < AnchorAnim.StandardSmall || type > AnchorAnim.SlowSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;

        if (type == AnchorAnim.FastSpatial)
            return Tokens.anim.durations.expressiveFastSpatial;
        if (type == AnchorAnim.DefaultSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;
        if (type == AnchorAnim.SlowSpatial)
            return Tokens.anim.durations.expressiveSlowSpatial;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4; // 0-7 are the 4 standard types
        return Tokens.anim.durations[types[idx]];
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        if (type == AnchorAnim.FastSpatial)
            return [0.2, 1.0, 0.32, 1.0, 1.0, 1.0];
        if (type == AnchorAnim.DefaultSpatial)
            return [0.16, 1.0, 0.3, 1.0, 1.0, 1.0];
        if (type == AnchorAnim.SlowSpatial)
            return [0.14, 1.0, 0.28, 1.0, 1.0, 1.0];

        if (type >= AnchorAnim.EmphasizedSmall && type <= AnchorAnim.EmphasizedExtraLarge)
            return [0.16, 1.0, 0.3, 1.0, 1.0, 1.0];
        if (type >= AnchorAnim.StandardSmall && type <= AnchorAnim.StandardExtraLarge)
            return [0.22, 1.0, 0.36, 1.0, 1.0, 1.0];

        return [0.16, 1.0, 0.3, 1.0, 1.0, 1.0];
    }
}
