pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        nexusComp.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            // The size follows the screen, but the compositor only reads the implicit size when the
            // window is created. When the screen changes (e.g. a new display scale), resize and
            // re-centre the window ourselves.
            Connections {
                function onImplicitWidthChanged(): void {
                    resizeTimer.restart();
                }

                function onImplicitHeightChanged(): void {
                    resizeTimer.restart();
                }

                target: nexus
            }

            Timer {
                id: resizeTimer

                interval: 150
                onTriggered: {
                    // Hyprland has to be told which window; match this one by its title
                    const toplevel = Hypr.toplevels.values.find(t => t.title === win.title);
                    if (!toplevel)
                        return;
                    const addr = toplevel.address.startsWith("0x") ? toplevel.address : `0x${toplevel.address}`;
                    const w = Math.round(nexus.implicitWidth);
                    const h = Math.round(nexus.implicitHeight);
                    if (Hypr.usingLua) {
                        Hypr.dispatch(`hl.dsp.window.resize({ x = ${w}, y = ${h}, exact = true, window = "address:${addr}" })`);
                        Hypr.dispatch(`hl.dsp.window.center({ window = "address:${addr}" })`);
                    } else {
                        Hypr.dispatch(`resizewindowpixel exact ${w} ${h},address:${addr}`);
                        Hypr.dispatch(`centerwindow`);
                    }
                }
            }

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
