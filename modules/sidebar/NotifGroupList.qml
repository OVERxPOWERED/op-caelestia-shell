import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import qs.components
import qs.services
import qs.config

LazyListView {
    id: root

    required property Props props
    required property list<var> notifs
    required property bool expanded
    required property Flickable container
    required property DrawerVisibilities visibilities

    readonly property real nonAnimHeight: layoutHeight

    signal requestToggleExpand(expand: bool)

    Layout.fillWidth: true
    implicitHeight: contentHeight

    spacing: Math.round(Appearance.spacing.small / 2)
    asynchronous: true

    removeDuration: Appearance.anim.durations.normal

    useCustomViewport: true
    viewport: Qt.rect(0, container.contentY - mapToItem(container.contentItem, 0, 0).y, width, container.height)

    model: ScriptModel {
        values: root.expanded ? root.notifs : root.notifs.slice(0, Config.notifs.groupPreviewNum + 1)
    }

    delegate: Component {
        MouseArea {
            id: notif

            required property int index
            required property NotifData modelData

            readonly property bool previewHidden: {
                if (root.expanded)
                    return false;

                let extraHidden = 0;
                for (let i = 0; i < index; i++)
                    if (root.notifs[i]?.closed)
                        extraHidden++;

                return index >= Config.notifs.groupPreviewNum + extraHidden;
            }
            property int startY

            Component.onCompleted: modelData?.lock(this)
            Component.onDestruction: modelData?.unlock(this)

            LazyListView.preferredHeight: modelData?.closed || previewHidden ? 0 : notifInner.nonAnimHeight
            LazyListView.visibleHeight: modelData?.closed || previewHidden ? 0 : notifInner.implicitHeight
            implicitHeight: notifInner.implicitHeight

            opacity: LazyListView.removing || modelData?.closed || previewHidden || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || previewHidden ? 0.7 : LazyListView.adding ? 0.7 : 1

            hoverEnabled: true
            cursorShape: notifInner.body?.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: !root.expanded
            enabled: !(modelData?.closed ?? true)

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    root.requestToggleExpand(!root.expanded);
                else if (event.button === Qt.MiddleButton)
                    modelData?.close();
            }
            onPositionChanged: event => {
                if (pressed && !root.expanded) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        root.requestToggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    modelData?.close();
            }

            ParallelAnimation {
                running: notif.modelData?.closed ?? false
                onFinished: notif.modelData?.unlock(notif)

                Anim {
                    target: notif
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: notif
                    property: "x"
                    to: notif.x >= 0 ? notif.width : -notif.width
                }
            }

            Notif {
                id: notifInner

                anchors.fill: parent
                modelData: notif.modelData
                props: root.props
                expanded: root.expanded
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
                Anim {}
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
