import QtQuick
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services

MaterialShape {
    id: root

    property list<int> shapes: {
        if (containsIcon)
            return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
        return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
    }
    property int shapeIndex
    property real cRotation
    property real lRotation
    property bool containsIcon

    property bool animated: true
    property int morphAnimRotation: 60
    property alias morphAnimDelay: morphAnimDelay.duration
    property alias rotateAnimDuration: rotateAnim.duration

    readonly property easingCurve scaleCurve: [0.00, 0.56, 0.55, 1.29, 1, 1]

    implicitSize: 38
    rotation: cRotation + lRotation

    shape: shapes[shapeIndex]
    color: Colours.palette.m3primary

    animationDuration: Tokens.anim.durations.expressiveSlowSpatial
    animationEasing: Tokens.anim.expressiveSlowSpatial

    scale: {
        const t = scaleCurve.valueForProgress(morphProgress);
        return 1 + 0.15 * Math.sin(t * Math.PI) / 2;
    }

    SequentialAnimation {
        running: root.animated
        loops: Animation.Infinite

        PropertyAction {
            target: root
            property: "shapeIndex"
            value: (root.shapeIndex + 1) % root.shapes.length
        }
        RotationAnimation {
            target: root
            property: "lRotation"
            to: (root.lRotation + root.morphAnimRotation) % 360
            duration: Tokens.anim.durations.expressiveSlowSpatial
            easing: Tokens.anim.expressiveSlowSpatial
            direction: RotationAnimation.Shortest
        }
        PauseAnimation {
            id: morphAnimDelay

            duration: 20
        }
    }

    RotationAnimation on cRotation {
        id: rotateAnim

        running: root.animated
        from: 0
        to: 360
        easing.type: Easing.Linear
        loops: Animation.Infinite
        duration: 10000
    }

    Behavior on color {
        CAnim {}
    }
}
