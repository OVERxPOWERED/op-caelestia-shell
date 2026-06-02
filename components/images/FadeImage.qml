import QtQuick
import Quickshell
import qs.components

Image {
    id: root

    property bool hadPrevious

    function maybeStartInAnim(): void {
        if (!opacityInAnim.running && status === Image.Ready) {
            opacityInAnim.type = hadPrevious ? Anim.DefaultEffects : Anim.StandardLarge;
            opacityInAnim.start();
        }
    }

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }

    retainWhileLoading: true
    opacity: 0

    onStatusChanged: maybeStartInAnim()

    Anim on opacity {
        id: opacityInAnim

        running: false
        to: 1
    }

    Behavior on source {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {
                target: root
                property: "hadPrevious"
                value: root.source
            }
            PropertyAction {}
            ScriptAction {
                script: root.maybeStartInAnim()
            }
        }
    }
}
