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
        }

        StyledWindow {
            id: win

            readonly property bool hasFullscreen: Hypr.monitorFor(screen)?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen === 2) ?? false
            readonly property int dragMaskPadding: {
                if (focusGrab.active || panels.popouts.isDetached)
                    return 0;

                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace?.name || mon?.activeWorkspace?.lastIpcObject.windows > 0)
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
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || panels.dashboard.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region {
                x: bar.clampedWidth + win.dragMaskPadding
                y: Config.border.clampedThickness + win.dragMaskPadding
                width: win.width - bar.clampedWidth - Config.border.clampedThickness - win.dragMaskPadding * 2
                height: win.height - Config.border.clampedThickness * 2 - win.dragMaskPadding * 2
                intersection: Intersection.Xor

                regions: regions.instances // qmllint disable stale-property-read
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + bar.implicitWidth
                    y: modelData.y + Config.border.thickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
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
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
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
                }

                BlobInvertedRect {
                    anchors.fill: parent
                    anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
                    group: blobGroup
                    radius: Config.border.rounding
                    borderLeft: bar.implicitWidth - anchors.margins
                    borderRight: Config.border.thickness - anchors.margins
                    borderTop: Config.border.thickness - anchors.margins
                    borderBottom: Config.border.thickness - anchors.margins
                }

                PanelBg {
                    id: dashBg

                    blobGroup: blobGroup
                    panel: panels.dashboard
                    bar: bar
                    deformAmount: 0.1
                }

                PanelBg {
                    id: launcherBg

                    blobGroup: blobGroup
                    panel: panels.launcher
                    bar: bar
                    deformAmount: 0.1
                }

                PanelBg {
                    id: sessionBg

                    blobGroup: blobGroup
                    panel: panels.session
                    bar: bar
                    deformAmount: 0.25
                }

                PanelBg {
                    id: sidebarBg

                    blobGroup: blobGroup
                    panel: panels.sidebar
                    bar: bar
                    deformAmount: 0
                }

                PanelBg {
                    id: osdBg

                    blobGroup: blobGroup
                    panel: panels.osd
                    bar: bar
                    deformAmount: 0.3
                }

                PanelBg {
                    id: notifsBg

                    blobGroup: blobGroup
                    panel: panels.notifications
                    bar: bar
                }

                PanelBg {
                    id: utilsBg

                    blobGroup: blobGroup
                    panel: panels.utilities
                    bar: bar
                }

                PanelBg {
                    id: popoutBg

                    blobGroup: blobGroup
                    panel: panels.popouts
                    bar: bar

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

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar

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

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }

    component PanelBg: BlobRect {
        required property BlobGroup blobGroup
        required property Item panel
        required property Item bar
        property real deformAmount: 0.15

        group: panel.width > 0 && panel.height > 0 ? blobGroup : null
        x: panel.x + bar.implicitWidth
        y: panel.y + Config.border.thickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Config.border.rounding
        deformScale: deformAmount / 10000
    }
}
