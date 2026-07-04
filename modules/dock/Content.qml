pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.launcher.services
import QtQml.Models

Item {
    id: root

    required property ScreenState screenState
    required property var panels

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property int itemSize: Tokens.sizes.launcher.itemHeight * 1.2
    readonly property int iconSize: itemSize * 0.7

    property bool editMode: false

    onEditModeChanged: {
        if (!editMode && typeof visualModel !== "undefined" && visualModel.items) {
            let arr = [];
            for (let i = 0; i < visualModel.items.count; i++) {
                arr.push(visualModel.items.get(i).model.modelData);
            }
            GlobalConfig.dock.pinnedApps = arr;
        }
    }

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2

    // Helper to get DesktopEntry from an ID string
    function getAppEntry(id: string) {
        if (!id) return null;
        for (let i = 0; i < Apps.list.length; ++i) {
            if (Apps.list[i].id === id) {
                return Apps.list[i].entry;
            }
        }
        return null;
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        ListView {
            id: listView
            width: count * root.itemSize + Math.max(0, count - 1) * Tokens.spacing.medium
            height: root.itemSize
            orientation: ListView.Horizontal
            spacing: Tokens.spacing.medium
            interactive: false

            displaced: Transition {
                Anim { properties: "x,y" }
            }

            model: DelegateModel {
                id: visualModel
                model: GlobalConfig.dock.pinnedApps

                delegate: DropArea {
                    id: delegateRoot
                    width: root.itemSize
                    height: root.itemSize
                    
                    required property string modelData
                    required property int index

                    readonly property var entry: root.getAppEntry(modelData)
                    
                    keys: ["dockItem"]

                    onEntered: (drag) => {
                        if (drag.source.visualIndex !== undefined) {
                            let from = drag.source.visualIndex;
                            let to = delegateRoot.DelegateModel.itemsIndex;
                            if (from !== to) {
                                visualModel.items.move(from, to);
                            }
                        }
                    }

                    Item {
                        id: contentItem
                        width: root.itemSize
                        height: root.itemSize

                        Drag.active: dragHandler.active
                        Drag.source: contentItem
                        Drag.keys: ["dockItem"]
                        property int visualIndex: delegateRoot.DelegateModel.itemsIndex

                        DragHandler {
                            id: dragHandler
                            enabled: root.editMode
                            target: contentItem
                            xAxis.enabled: true
                            yAxis.enabled: false
                            // We don't save to GlobalConfig on drop anymore to prevent glitching.
                            // We will save when editMode is turned off instead.
                        }

                        states: [
                            State {
                                when: dragHandler.active
                                ParentChange {
                                    target: contentItem
                                    parent: listView
                                }
                                AnchorChanges {
                                    target: contentItem
                                    anchors.horizontalCenter: undefined
                                    anchors.verticalCenter: undefined
                                }
                                PropertyChanges {
                                    target: contentItem
                                    opacity: 0.8
                                    z: 10
                                }
                            }
                        ]

                        StateLayer {
                            radius: Tokens.rounding.large
                            anchors.fill: parent
                            onClicked: {
                                if (root.editMode) return;
                                if (entry) {
                                    Apps.launch(entry);
                                    root.screenState.dock = false;
                                }
                            }
                            onPressAndHold: root.editMode = true
                        }

                        IconImage {
                            asynchronous: true
                            source: Quickshell.iconPath(entry?.icon, "image-missing")
                            width: root.iconSize
                            height: root.iconSize
                            anchors.centerIn: parent
                        }

                        // Edit mode overlay
                        Rectangle {
                            visible: root.editMode
                            width: root.iconSize * 0.4
                            height: width
                            radius: width / 2
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -width / 4
                            anchors.rightMargin: -width / 4
                            z: 10 // Ensure it's above everything to capture clicks

                            color: Colours.palette.m3error
                            border.width: 2
                            border.color: Colours.palette.m3surface

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "remove"
                                color: Colours.palette.m3onError
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let newApps = [...GlobalConfig.dock.pinnedApps];
                                    newApps.splice(index, 1);
                                    GlobalConfig.dock.pinnedApps = newApps;
                                }
                            }
                        }
                        
                        // Subtle wobble animation in edit mode
                        SequentialAnimation on rotation {
                            running: root.editMode && !dragHandler.active
                            loops: Animation.Infinite
                            Anim { from: 0; to: 3; duration: 150; type: Anim.DefaultEffects }
                            Anim { from: 3; to: -3; duration: 300; type: Anim.DefaultEffects }
                            Anim { from: -3; to: 0; duration: 150; type: Anim.DefaultEffects }
                        }
                    }
                }
            }
        }

        // Add button (only shown if slots are available and not in edit mode)
        Item {
            width: root.itemSize
            height: root.itemSize
            visible: GlobalConfig.dock.pinnedApps.length < GlobalConfig.dock.maxSlots && !root.editMode

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: {
                    root.screenState.launcherPickCallback = (app) => {
                        let arr = [...GlobalConfig.dock.pinnedApps];
                        arr.push(app.id);
                        GlobalConfig.dock.pinnedApps = arr;
                    };
                    root.screenState.launcher = true;
                    // Keep dock visible so we see it added, or we can hide it:
                    root.screenState.dock = false;
                }
            }

            MaterialIcon {
                text: "add"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.extraLarge
                anchors.centerIn: parent
            }
        }

        // Settings / Edit mode toggle
        Item {
            width: root.itemSize
            height: root.itemSize

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: root.editMode = !root.editMode
            }

            MaterialIcon {
                text: root.editMode ? "check" : "edit"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.large
                anchors.centerIn: parent
            }
        }
    }
}
