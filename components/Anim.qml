import QtQuick
import Caelestia.Config

NumberAnimation {
    duration: Tokens.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Tokens.anim.curves.standard
}
