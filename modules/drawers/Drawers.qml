pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import qs.modules.bar

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData
        readonly property bool barDisabled: Strings.testRegexList(Config.bar.excludedScreens, modelData.name)

        Exclusions {
            screen: scope.modelData
            bar: bar
            borderThickness: Config.border.thickness
        }

        StyledWindow {
            id: win

            readonly property var monitor: Hypr.monitorFor(screen)
            readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject?.specialWorkspace?.name.length ?? 0) > 0
            readonly property bool hasFullscreen: {
                if (hasSpecialWorkspace) {
                    const specialName = monitor?.lastIpcObject?.specialWorkspace?.name;
                    if (!specialName)
                        return false;
                    const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
                    return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
                }
                return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
            }
            property real borderThickness: hasFullscreen ? 0 : Config.border.thickness
            readonly property real borderLayoutThickness: hasFullscreen ? 0 : Config.border.thickness
            property real borderRounding: hasFullscreen ? 0 : Config.border.rounding
            property real shadowOpacity: hasFullscreen ? 0 : 0.7
            readonly property int dragMaskPadding: {
                if (focusGrab.active || panels.popouts.isDetached)
                    return 0;

                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace?.name || mon?.activeWorkspace.lastIpcObject.windows > 0)
                    return 0;

                const thresholds = [];
                for (const panel of ["dashboard", "launcher", "session", "sidebar"])
                    if (Config[panel].enabled)
                        thresholds.push(Config[panel].dragThreshold);
                return Math.max(...thresholds);
            }

            onHasFullscreenChanged: {
                visibilities.launcher = false;
                visibilities.session = false;
                visibilities.dashboard = false;
            }

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || panels.dashboard.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Regions {
                bar: bar
                panels: panels
                win: win
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Behavior on borderThickness {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on borderRounding {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on shadowOpacity {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled) || (visibilities.sidebar && Config.sidebar.enabled) || (!Config.dashboard.showOnHover && visibilities.dashboard && Config.dashboard.enabled) || (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                windows: [win]
                onCleared: {
                    visibilities.launcher = false;
                    visibilities.session = false;
                    visibilities.sidebar = false;
                    visibilities.dashboard = false;
                    panels.popouts.hasCurrent = false;
                    bar.closeTray();
                }
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, win.shadowOpacity))
                }

                // Border {
                //     bar: bar
                // }

                // Backgrounds {
                //     panels: panels
                //     bar: bar
                // }

                BlobGroup {
                    id: blobGroup

                    color: Colours.palette.m3surface

                    Behavior on color {
                        CAnim {}
                    }
                }

                BlobInvertedRect {
                    anchors.fill: parent
                    anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
                    group: blobGroup
                    radius: win.borderRounding
                    borderLeft: bar.implicitWidth - anchors.margins
                    borderRight: win.borderThickness - anchors.margins
                    borderTop: win.borderThickness - anchors.margins
                    borderBottom: win.borderThickness - anchors.margins
                }

                PanelBg {
                    id: dashBg

                    blobGroup: blobGroup
                    panel: panels.dashboard
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: 0.1
                }

                PanelBg {
                    id: launcherBg

                    blobGroup: blobGroup
                    panel: panels.launcher
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: 0.1
                }

                PanelBg {
                    id: sessionBg

                    blobGroup: blobGroup
                    panel: panels.sessionWrapper
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: 0.25
                    x: panels.sessionWrapper.x + panels.session.x + bar.implicitWidth
                    implicitWidth: panels.session.width
                }

                PanelBg {
                    id: sidebarBg

                    blobGroup: blobGroup
                    panel: panels.sidebar
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: 0.05
                    implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
                    exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
                    bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
                }

                PanelBg {
                    id: osdBg

                    blobGroup: blobGroup
                    panel: panels.osdWrapper
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: 0.3
                    x: panels.osdWrapper.x + panels.osd.x + bar.implicitWidth
                    implicitWidth: panels.osd.width
                }

                PanelBg {
                    id: notifsBg

                    blobGroup: blobGroup
                    panel: panels.notifications
                    bar: bar
                    borderThickness: win.borderThickness
                }

                PanelBg {
                    id: utilsBg

                    blobGroup: blobGroup
                    panel: panels.utilities
                    bar: bar
                    borderThickness: win.borderThickness
                    deformAmount: panels.sidebar.visible ? 0.1 : 0.15
                    exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
                    topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
                }

                PanelBg {
                    id: popoutBg

                    blobGroup: blobGroup
                    panel: panels.popouts
                    bar: bar
                    borderThickness: win.borderThickness

                    x: bar.implicitWidth - (panels.popouts.isDetached ? -(win.width - panels.popouts.shownWidth) / 2 : panels.popouts.hasCurrent ? 0 : panels.popouts.shownWidth + 5)
                    implicitWidth: panels.popouts.shownWidth

                    Behavior on x {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                }
            }

            DrawerVisibilities {
                id: visibilities

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar
                borderThickness: win.borderLayoutThickness
                fullscreen: win.hasFullscreen

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                    borderThickness: win.borderThickness

                    utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1

                    dashboard.transform: Matrix4x4 {
                        matrix: dashBg.deformMatrix
                    }
                    launcher.transform: Matrix4x4 {
                        matrix: launcherBg.deformMatrix
                    }
                    session.transform: Matrix4x4 {
                        matrix: sessionBg.deformMatrix
                    }
                    sidebar.transform: Matrix4x4 {
                        matrix: sidebarBg.deformMatrix
                    }
                    osd.transform: Matrix4x4 {
                        matrix: osdBg.deformMatrix
                    }
                    notifications.transform: Matrix4x4 {
                        matrix: notifsBg.deformMatrix
                    }
                    utilities.transform: Matrix4x4 {
                        matrix: utilsBg.deformMatrix
                    }
                    popouts.transform: Matrix4x4 {
                        matrix: popoutBg.deformMatrix
                    }
                }

                BarWrapper {
                    id: bar

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts

                    disabled: scope.barDisabled
                    fullscreen: win.hasFullscreen

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }

    component PanelBg: BlobRect {
        required property BlobGroup blobGroup
        required property Item panel
        required property Item bar
        required property real borderThickness
        property real deformAmount: 0.15

        group: panel.width > 0 && panel.height > 0 ? blobGroup : null
        x: panel.x + bar.implicitWidth
        y: panel.y + borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Config.border.rounding
        deformScale: deformAmount / 10000
    }
}
