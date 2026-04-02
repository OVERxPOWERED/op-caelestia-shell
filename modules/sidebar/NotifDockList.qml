import QtQuick
import Quickshell
import Caelestia.Components
import qs.components
import qs.services
import qs.config

LazyListView {
    id: root

    required property Props props
    required property Flickable container
    required property DrawerVisibilities visibilities

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: contentHeight

    spacing: Appearance.spacing.small
    cacheBuffer: 200

    useCustomViewport: true
    viewport: Qt.rect(0, container.contentY, width, container.height)

    addDuration: Appearance.anim.durations.expressiveDefaultSpatial
    addCurve.type: Easing.BezierSpline
    addCurve.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    addFromOpacity: 0
    addFromScale: 0

    removeDuration: Appearance.anim.durations.normal
    removeCurve.type: Easing.BezierSpline
    removeCurve.bezierCurve: Appearance.anim.curves.standard
    removeToOpacity: 0
    removeToScale: 0.6

    moveDuration: Appearance.anim.durations.expressiveDefaultSpatial
    moveCurve.type: Easing.BezierSpline
    moveCurve.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial

    model: ScriptModel {
        values: {
            const map = new Map();
            for (const n of Notifs.notClosed)
                map.set(n.appName, null);
            for (const n of Notifs.list)
                map.set(n.appName, null);
            return [...map.keys()];
        }
    }

    delegate: Component {
        MouseArea {
            id: notif

            required property int index
            required property string modelData

            readonly property bool closed: notifInner.notifCount === 0
            property int startY

            function closeAll(): void {
                for (const n of Notifs.notClosed.filter(n => n.appName === modelData))
                    n.close();
            }

            containmentMask: QtObject {
                function contains(p: point): bool {
                    if (!root.container.contains(notif.mapToItem(root.container, p)))
                        return false;
                    return notifInner.contains(p);
                }
            }

            LazyListView.preferredHeight: closed ? 0 : notifInner.nonAnimHeight
            implicitHeight: notifInner.implicitHeight

            opacity: LazyListView.removing || closed || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || closed ? 0.6 : LazyListView.adding ? 0 : 1

            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: true
            enabled: !closed

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    notifInner.toggleExpand(!notifInner.expanded);
                else if (event.button === Qt.MiddleButton)
                    closeAll();
            }
            onPositionChanged: event => {
                if (pressed) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        notifInner.toggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    closeAll();
            }

            NotifGroup {
                id: notifInner

                modelData: notif.modelData
                props: root.props
                container: root.container
                visibilities: root.visibilities
            }

            Behavior on y {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }
}
