pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import Caelestia.Models
import QtQuick

Item {
    id: root

    required property Session session

    property alias layoutPreferredHeight: wallpaperGrid.layoutPreferredHeight

    // Find and store reference to parent Flickable for scroll monitoring
    property var parentFlickable: {
        let item = parent;
        while (item) {
            if (item.flickableDirection !== undefined) {
                return item;
            }
            item = item.parent;
        }
        return null;
    }

    // Cleanup when component is destroyed
    Component.onDestruction: {
        if (wallpaperGrid) {
            if (wallpaperGrid.scrollCheckTimer) {
                wallpaperGrid.scrollCheckTimer.stop();
            }
            wallpaperGrid._expansionInProgress = false;
        }
    }

    QtObject {
        id: lazyModel

        property var sourceList: null
        property int loadedCount: 0
        property int visibleCount: 0
        property int totalCount: 0

        function initialize(list) {
            sourceList = list;
            totalCount = list ? list.length : 0;
            const initialRows = 3;
            const cols = wallpaperGrid.columnsCount > 0 ? wallpaperGrid.columnsCount : 3;
            const initialCount = Math.min(initialRows * cols, totalCount);
            loadedCount = initialCount;
            visibleCount = initialCount;
        }

        function loadOneRow() {
            if (loadedCount < totalCount) {
                const cols = wallpaperGrid.columnsCount > 0 ? wallpaperGrid.columnsCount : 1;
                const itemsToLoad = Math.min(cols, totalCount - loadedCount);
                loadedCount += itemsToLoad;
            }
        }

        function updateVisibleCount(neededCount) {
            const cols = wallpaperGrid.columnsCount > 0 ? wallpaperGrid.columnsCount : 1;
            const maxVisible = Math.min(neededCount, loadedCount);
            const rows = Math.ceil(maxVisible / cols);
            const newVisibleCount = Math.min(rows * cols, loadedCount);

            if (newVisibleCount > visibleCount) {
                visibleCount = newVisibleCount;
            }
        }
    }

    GridView {
        id: wallpaperGrid
        anchors.fill: parent

        property int _delegateCount: 0

        readonly property int minCellWidth: 200 + Appearance.spacing.normal
        readonly property int columnsCount: Math.max(1, Math.floor(parent.width / minCellWidth))

        readonly property int layoutPreferredHeight: {
            if (!lazyModel || lazyModel.visibleCount === 0 || columnsCount === 0) {
                return 0;
            }
            const calculated = Math.ceil(lazyModel.visibleCount / columnsCount) * cellHeight;
            return calculated;
        }

        height: layoutPreferredHeight
        cellWidth: width / columnsCount
        cellHeight: 140 + Appearance.spacing.normal

        leftMargin: 0
        rightMargin: 0
        topMargin: 0
        bottomMargin: 0

        ListModel {
            id: wallpaperListModel
        }

        model: wallpaperListModel

        Connections {
            target: lazyModel
            function onVisibleCountChanged(): void {
                if (!lazyModel || !lazyModel.sourceList) return;

                const newCount = lazyModel.visibleCount;
                const currentCount = wallpaperListModel.count;

                if (newCount > currentCount) {
                    const flickable = root.parentFlickable;
                    const oldScrollY = flickable ? flickable.contentY : 0;

                    for (let i = currentCount; i < newCount; i++) {
                        wallpaperListModel.append({modelData: lazyModel.sourceList[i]});
                    }

                    if (flickable) {
                        Qt.callLater(function() {
                            if (Math.abs(flickable.contentY - oldScrollY) < 1) {
                                flickable.contentY = oldScrollY;
                            }
                        });
                    }
                }
            }
        }

        Component.onCompleted: {
            Qt.callLater(function() {
                const isActive = root.session.activeIndex === 3;
                if (width > 0 && parent && parent.visible && isActive && Wallpapers.list) {
                    lazyModel.initialize(Wallpapers.list);
                    wallpaperListModel.clear();
                    for (let i = 0; i < lazyModel.visibleCount; i++) {
                        wallpaperListModel.append({modelData: lazyModel.sourceList[i]});
                    }
                }
            });
        }

        Connections {
            target: root.session
            function onActiveIndexChanged(): void {
                const isActive = root.session.activeIndex === 3;

                // Stop lazy loading when switching away from appearance pane
                if (!isActive) {
                    if (scrollCheckTimer) {
                        scrollCheckTimer.stop();
                    }
                    if (wallpaperGrid) {
                        wallpaperGrid._expansionInProgress = false;
                    }
                    return;
                }

                // Initialize if needed when switching to appearance pane
                if (isActive && width > 0 && !lazyModel.sourceList && parent && parent.visible && Wallpapers.list) {
                    lazyModel.initialize(Wallpapers.list);
                    wallpaperListModel.clear();
                    for (let i = 0; i < lazyModel.visibleCount; i++) {
                        wallpaperListModel.append({modelData: lazyModel.sourceList[i]});
                    }
                }
            }
        }

        onWidthChanged: {
            const isActive = root.session.activeIndex === 3;
            if (width > 0 && !lazyModel.sourceList && parent && parent.visible && isActive && Wallpapers.list) {
                lazyModel.initialize(Wallpapers.list);
                wallpaperListModel.clear();
                for (let i = 0; i < lazyModel.visibleCount; i++) {
                    wallpaperListModel.append({modelData: lazyModel.sourceList[i]});
                }
            }
        }

        // Force true lazy loading: only create delegates for visible items
        displayMarginBeginning: 0
        displayMarginEnd: 0
        cacheBuffer: 0

        // Debounce expansion to avoid too frequent checks
        property bool _expansionInProgress: false

        Connections {
            target: root.parentFlickable
            function onContentYChanged(): void {
                // Don't process scroll events if appearance pane is not active
                const isActive = root.session.activeIndex === 3;
                if (!isActive) return;

                if (!lazyModel || !lazyModel.sourceList || lazyModel.loadedCount >= lazyModel.totalCount || wallpaperGrid._expansionInProgress) {
                    return;
                }

                const flickable = root.parentFlickable;
                if (!flickable) return;

                const gridY = root.y;
                const scrollY = flickable.contentY;
                const viewportHeight = flickable.height;

                const topY = scrollY - gridY;
                const bottomY = scrollY + viewportHeight - gridY;

                if (bottomY < 0) return;

                const topRow = Math.max(0, Math.floor(topY / wallpaperGrid.cellHeight));
                const bottomRow = Math.floor(bottomY / wallpaperGrid.cellHeight);

                // Update visible count with 1 row buffer ahead
                const bufferRows = 1;
                const neededBottomRow = bottomRow + bufferRows;
                const neededCount = Math.min((neededBottomRow + 1) * wallpaperGrid.columnsCount, lazyModel.loadedCount);
                lazyModel.updateVisibleCount(neededCount);

                const loadedRows = Math.ceil(lazyModel.loadedCount / wallpaperGrid.columnsCount);
                const rowsRemaining = loadedRows - (bottomRow + 1);

                if (rowsRemaining <= 1 && lazyModel.loadedCount < lazyModel.totalCount) {
                    if (!wallpaperGrid._expansionInProgress) {
                        wallpaperGrid._expansionInProgress = true;
                        lazyModel.loadOneRow();
                        Qt.callLater(function() {
                            wallpaperGrid._expansionInProgress = false;
                        });
                    }
                }
            }
        }

        // Fallback timer to check scroll position periodically
        Timer {
            id: scrollCheckTimer
            interval: 100
            running: {
                const isActive = root.session.activeIndex === 3;
                return isActive && lazyModel && lazyModel.sourceList && lazyModel.loadedCount < lazyModel.totalCount;
            }
            repeat: true
            onTriggered: {
                // Double-check that appearance pane is still active
                const isActive = root.session.activeIndex === 3;
                if (!isActive) {
                    stop();
                    return;
                }

                const flickable = root.parentFlickable;
                if (!flickable || !lazyModel || !lazyModel.sourceList) return;

                const gridY = root.y;
                const scrollY = flickable.contentY;
                const viewportHeight = flickable.height;

                const topY = scrollY - gridY;
                const bottomY = scrollY + viewportHeight - gridY;
                if (bottomY < 0) return;

                const topRow = Math.max(0, Math.floor(topY / wallpaperGrid.cellHeight));
                const bottomRow = Math.floor(bottomY / wallpaperGrid.cellHeight);

                const bufferRows = 1;
                const neededBottomRow = bottomRow + bufferRows;
                const neededCount = Math.min((neededBottomRow + 1) * wallpaperGrid.columnsCount, lazyModel.loadedCount);
                lazyModel.updateVisibleCount(neededCount);

                const loadedRows = Math.ceil(lazyModel.loadedCount / wallpaperGrid.columnsCount);
                const rowsRemaining = loadedRows - (bottomRow + 1);

                if (rowsRemaining <= 1 && lazyModel.loadedCount < lazyModel.totalCount) {
                    if (!wallpaperGrid._expansionInProgress) {
                        wallpaperGrid._expansionInProgress = true;
                        lazyModel.loadOneRow();
                        Qt.callLater(function() {
                            wallpaperGrid._expansionInProgress = false;
                        });
                    }
                }
            }
        }

        interactive: false

        delegate: Item {
            required property var modelData

            width: wallpaperGrid.cellWidth
            height: wallpaperGrid.cellHeight

            readonly property bool isCurrent: modelData.path === Wallpapers.actualCurrent
            readonly property real itemMargin: Appearance.spacing.normal / 2
            readonly property real itemRadius: Appearance.rounding.normal

            Component.onCompleted: {
                wallpaperGrid._delegateCount++;
            }

            StateLayer {
                anchors.fill: parent
                anchors.leftMargin: itemMargin
                anchors.rightMargin: itemMargin
                anchors.topMargin: itemMargin
                anchors.bottomMargin: itemMargin
                radius: itemRadius

                function onClicked(): void {
                    Wallpapers.setWallpaper(modelData.path);
                }
            }

            StyledClippingRect {
                id: image

                anchors.fill: parent
                anchors.leftMargin: itemMargin
                anchors.rightMargin: itemMargin
                anchors.topMargin: itemMargin
                anchors.bottomMargin: itemMargin
                color: Colours.tPalette.m3surfaceContainer
                radius: itemRadius
                antialiasing: true
                layer.enabled: true
                layer.smooth: true

                CachingImage {
                    id: cachingImage

                    path: modelData.path
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    visible: opacity > 0
                    antialiasing: true
                    smooth: true

                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // Fallback if CachingImage fails to load
                Image {
                    id: fallbackImage

                    anchors.fill: parent
                    source: fallbackTimer.triggered && cachingImage.status !== Image.Ready ? modelData.path : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    visible: opacity > 0
                    antialiasing: true
                    smooth: true

                    opacity: status === Image.Ready && cachingImage.status !== Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Timer {
                    id: fallbackTimer

                    property bool triggered: false
                    interval: 800
                    running: cachingImage.status === Image.Loading || cachingImage.status === Image.Null
                    onTriggered: triggered = true
                }

                // Gradient overlay for filename
                Rectangle {
                    id: filenameOverlay

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    implicitHeight: filenameText.implicitHeight + Appearance.padding.normal * 1.5
                    radius: 0

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                                          Colours.palette.m3surfaceContainer.g,
                                          Colours.palette.m3surfaceContainer.b, 0)
                        }
                        GradientStop {
                            position: 0.3
                            color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                                          Colours.palette.m3surfaceContainer.g,
                                          Colours.palette.m3surfaceContainer.b, 0.7)
                        }
                        GradientStop {
                            position: 0.6
                            color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                                          Colours.palette.m3surfaceContainer.g,
                                          Colours.palette.m3surfaceContainer.b, 0.9)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                                          Colours.palette.m3surfaceContainer.g,
                                          Colours.palette.m3surfaceContainer.b, 0.95)
                        }
                    }

                    opacity: 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
                        opacity = 1;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: itemMargin
                anchors.rightMargin: itemMargin
                anchors.topMargin: itemMargin
                anchors.bottomMargin: itemMargin
                color: "transparent"
                radius: itemRadius + border.width
                border.width: isCurrent ? 2 : 0
                border.color: Colours.palette.m3primary
                antialiasing: true
                smooth: true

                Behavior on border.width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                MaterialIcon {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.padding.small

                    visible: isCurrent
                    text: "check_circle"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }
            }

            StyledText {
                id: filenameText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
                anchors.rightMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
                anchors.bottomMargin: Appearance.padding.normal

                readonly property string fileName: {
                    const path = modelData.relativePath || "";
                    const parts = path.split("/");
                    return parts.length > 0 ? parts[parts.length - 1] : path;
                }

                text: fileName
                font.pointSize: Appearance.font.size.smaller
                font.weight: 500
                color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                elide: Text.ElideMiddle
                maximumLineCount: 1
                horizontalAlignment: Text.AlignHCenter

                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutCubic
                    }
                }

                Component.onCompleted: {
                    opacity = 1;
                }
            }
        }
    }
}

