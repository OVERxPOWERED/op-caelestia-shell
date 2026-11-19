import QtQuick
import Caelestia.Config

NumberAnimation {
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
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        if (type < Anim.StandardSmall || type > Anim.SlowEffects)
            return Tokens.anim.durations.normal;

        if (type === Anim.FastSpatial)
            return Tokens.anim.durations.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return Tokens.anim.durations.expressiveSlowSpatial;
        if (type === Anim.FastEffects)
            return Tokens.anim.durations.expressiveFastEffects;
        if (type === Anim.DefaultEffects)
            return Tokens.anim.durations.expressiveDefaultEffects;
        if (type === Anim.SlowEffects)
            return Tokens.anim.durations.expressiveSlowEffects;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4; // 0-7 are the 4 standard types
        return Tokens.anim.durations[types[idx]];
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        if (type === Anim.FastSpatial)
            return [0.2, 1.0, 0.32, 1.0, 1.0, 1.0];
        if (type === Anim.DefaultSpatial)
            return [0.16, 1.0, 0.3, 1.0, 1.0, 1.0];
        if (type === Anim.SlowSpatial)
            return [0.14, 1.0, 0.28, 1.0, 1.0, 1.0];
        if (type >= Anim.FastEffects && type <= Anim.SlowEffects)
            return [0.22, 1.0, 0.36, 1.0, 1.0, 1.0];

        if (type >= Anim.EmphasizedSmall && type <= Anim.EmphasizedExtraLarge)
            return [0.16, 1.0, 0.3, 1.0, 1.0, 1.0];
        return [0.22, 1.0, 0.36, 1.0, 1.0, 1.0];
    }
}
