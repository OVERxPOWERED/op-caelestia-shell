pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property var menuItems: []
    readonly property real menuHeight: menu.implicitHeight

    function open(x: real, y: real, items: var): void {
        menuX = x;
        menuY = y;
        menuItems = items;
        expanded = true;
    }

    function close(): void {
        expanded = false;
    }

    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow;
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow).contentItem;
    }
    anchors.fill: parent

    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Elevation {
        id: menu

        x: Math.min(Math.max(0, root.menuX), (root.parent?.width ?? 0) - width - Tokens.padding.medium)
        y: Math.max(Tokens.padding.medium, root.menuY - height - Tokens.padding.small)

        radius: Tokens.rounding.large
        level: 2

        implicitWidth: 260
        implicitHeight: column.implicitHeight + column.anchors.margins * 2

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: menu.height

            Behavior on yScale {
                Anim {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                spacing: 0

                Repeater {
                    id: repeater

                    model: root.menuItems

                    StyledRect {
                        id: menuEntry

                        required property var modelData
                        required property int index

                        readonly property bool isSep: modelData.separator === true
                        readonly property bool hasClose: !isSep && modelData.closeAction !== undefined && modelData.closeAction !== null

                        Layout.fillWidth: true
                        implicitWidth: isSep ? 0 : optionRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: isSep
                            ? sepLine.height + Tokens.padding.extraSmall * 2
                            : optionRow.implicitHeight + Tokens.padding.medium * 2

                        color: "transparent"
                        radius: Tokens.rounding.extraSmall
                        topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                        topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                        bottomLeftRadius: index === repeater.count - 1 ? Tokens.rounding.medium : radius
                        bottomRightRadius: index === repeater.count - 1 ? Tokens.rounding.medium : radius

                        // Separator line
                        Rectangle {
                            id: sepLine
                            visible: menuEntry.isSep
                            width: parent.width - Tokens.padding.medium * 2
                            height: 1
                            anchors.centerIn: parent
                            color: Colours.palette.m3outlineVariant
                            opacity: 0.5
                        }

                        // Interaction layer for menu items
                        StateLayer {
                            visible: !menuEntry.isSep
                            disabled: !root.expanded || menuEntry.isSep
                            // Shrink to leave room for close button
                            anchors.rightMargin: menuEntry.hasClose ? closeBtn.width : 0
                            topLeftRadius: menuEntry.topLeftRadius
                            topRightRadius: menuEntry.hasClose ? Tokens.rounding.extraSmall : menuEntry.topRightRadius
                            bottomLeftRadius: menuEntry.bottomLeftRadius
                            bottomRightRadius: menuEntry.hasClose ? Tokens.rounding.extraSmall : menuEntry.bottomRightRadius
                            color: Colours.palette.m3onSurface
                            onClicked: {
                                if (menuEntry.modelData.action)
                                    menuEntry.modelData.action();
                                root.expanded = false;
                            }
                        }

                        // Menu item content
                        RowLayout {
                            id: optionRow
                            visible: !menuEntry.isSep
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: menuEntry.modelData?.icon ?? ""
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: menuEntry.modelData?.text ?? ""
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            // Inline close button for instance items
                            StyledRect {
                                id: closeBtn
                                visible: menuEntry.hasClose
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: visible ? closeIcon.implicitWidth + Tokens.padding.small * 2 : 0
                                Layout.preferredHeight: visible ? closeIcon.implicitHeight + Tokens.padding.small * 2 : 0
                                radius: Tokens.rounding.small
                                color: closeMa.containsMouse ? Qt.alpha(Colours.palette.m3error, 0.15) : "transparent"

                                MaterialIcon {
                                    id: closeIcon
                                    anchors.centerIn: parent
                                    text: "close"
                                    color: closeMa.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                }

                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: 10
                                    onClicked: {
                                        if (menuEntry.modelData.closeAction)
                                            menuEntry.modelData.closeAction();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
