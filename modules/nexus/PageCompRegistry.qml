pragma Singleton

import QtQuick
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.wallandstyle

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
                Component {
                    WallpaperSelect {}
                }
                Component {
                    WallpaperCategory {}
                }
                Component {
                    ColourSelect {}
                }
            }
        }
    ]
}
