pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property Item panels

    readonly property int spacing: Appearance.spacing.small
    readonly property int maxToasts: 5
    readonly property bool listVisible: panels.notifications.content.shouldShow

    property bool flag
    property var activeToasts: new Set()

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: Appearance.padding.normal

    implicitWidth: Config.notifs.sizes.width
    implicitHeight: {
        if (listVisible)
            return 0;

        let height = -spacing;
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i) as ToastWrapper;
            if (item && !item.modelData.closed && !item.previewHidden)
                height += item.implicitHeight + spacing;
        }
        return height;
    }

    opacity: listVisible ? 0 : 1
    visible: opacity > 0

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: {
                const toasts = [];
                let visibleCount = 0;

                for (const notif of Notifs.list) {
                    if (notif.showAsToast) {
                        root.activeToasts.add(notif);
                    }
                    if (notif.closed) {
                        root.activeToasts.delete(notif);
                    }
                }

                for (const notif of Notifs.list) {
                    if (root.activeToasts.has(notif)) {
                        toasts.push(notif);
                        if (notif.showAsToast && !notif.closed) {
                            visibleCount++;
                            if (visibleCount > root.maxToasts)
                                break;
                        }
                    }
                }
                return toasts;
            }
            onValuesChanged: root.flagChanged()
        }

        ToastWrapper {}
    }

    component ToastWrapper: MouseArea {
        id: toast

        required property int index
        required property Notifs.Notif modelData

        readonly property bool previewHidden: {
            let extraHidden = 0;
            for (let i = 0; i < index; i++) {
                const item = repeater.itemAt(i);
                if (item && item.modelData.closed)
                    extraHidden++;
            }
            return index >= root.maxToasts + extraHidden;
        }

        opacity: modelData.closed || previewHidden || !modelData.showAsToast ? 0 : 1
        scale: modelData.closed || previewHidden || !modelData.showAsToast ? 0.7 : 1

        anchors.topMargin: {
            root.flag;
            let margin = 0;
            for (let i = 0; i < index; i++) {
                const item = repeater.itemAt(i) as ToastWrapper;
                if (item && !item.modelData.closed && !item.previewHidden)
                    margin += item.implicitHeight + root.spacing;
            }
            return margin;
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: toastInner.implicitHeight

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: {
            modelData.showAsToast = false;
            modelData.close();
        }

        Component.onCompleted: modelData.lock(this)

        onPreviewHiddenChanged: {
            if (initAnim.running && previewHidden)
                initAnim.stop();
        }

        Anim {
            id: initAnim

            Component.onCompleted: running = !toast.previewHidden

            target: toast
            properties: "opacity,scale"
            from: 0
            to: 1
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }

        ParallelAnimation {
            running: toast.modelData.closed || (!toast.modelData.showAsToast && !toast.modelData.closed)
            onStarted: toast.anchors.topMargin = toast.anchors.topMargin
            onFinished: {
                if (toast.modelData.closed)
                    toast.modelData.unlock(toast);
            }

            Anim {
                target: toast
                property: "opacity"
                to: 0
            }
            Anim {
                target: toast
                property: "scale"
                to: 0.7
            }
        }

        NotificationToast {
            id: toastInner

            modelData: toast.modelData
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on anchors.topMargin {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }
}
