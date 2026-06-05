pragma Singleton

import QtQuick
import qs.modules.nexus.common
import qs.modules.nexus.pages

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
            }
        }
    ]
}
