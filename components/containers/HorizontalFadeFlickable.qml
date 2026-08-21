pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.effects

StyledFlickable {
    id: root

    property real fadePixels: 24
    readonly property real fadeAmount: width > 0 ? Math.min(0.25, fadePixels / width) : 0.1

    property real leftFadeOpacity: fadeShouldBeActive(true) ? 0 : 1
    property real rightFadeOpacity: fadeShouldBeActive(false) ? 0 : 1

    function fadeShouldBeActive(isStart: bool): bool {
        // When content fits within width, do not fade
        if (contentWidth + leftMargin + rightMargin <= width)
            return false;

        if (contentWidth + leftMargin + rightMargin < width && rebound.running && ((isStart ? horizontalOvershoot > 0 : horizontalOvershoot < 0)))
            return false;

        if (isStart)
            return visibleArea.xPosition > 0.005;
        return visibleArea.xPosition + visibleArea.widthRatio < 0.995;
    }

    flickableDirection: Flickable.HorizontalFlick

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask

        Rectangle {
            id: mask

            anchors.fill: parent
            visible: false
            layer.enabled: true

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, root.leftFadeOpacity)
                }
                GradientStop {
                    position: root.fadeAmount
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1 - root.fadeAmount
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, root.rightFadeOpacity)
                }
            }
        }
    }

    Behavior on leftFadeOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on rightFadeOpacity {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
