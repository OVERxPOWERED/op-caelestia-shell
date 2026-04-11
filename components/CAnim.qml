import QtQuick
import Caelestia.Config

ColorAnimation {
    duration: Tokens.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Tokens.anim.curves.standard
}
