pragma ComponentBehavior: Bound

import "pages"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState

    readonly property list<Component> pageComps: [
        Component {
            WallpaperAndStyle {
                nState: root.nState
            }
        }
    ]

    property int lastPageIdx
    property int animOff

    Loader {
        id: loader

        anchors.fill: parent
        layer.enabled: opacity < 1
        Component.onCompleted: sourceComponent = root.pageComps[root.nState.currentPageIdx] ?? placeholderComp
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            switchAnim.complete();
            root.animOff = root.Tokens.padding.extraLarge * (root.nState.currentPageIdx > root.lastPageIdx ? -1 : 1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    SequentialAnimation {
        id: switchAnim

        Anim {
            target: loader
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
        PropertyAction {
            target: loader
            property: "sourceComponent"
            value: root.pageComps[root.nState.currentPageIdx] ?? placeholderComp
        }
        PropertyAction {
            target: loader.anchors
            property: "topMargin"
            value: root.animOff
        }
        PropertyAction {
            target: loader.anchors
            property: "bottomMargin"
            value: -root.animOff
        }
        ParallelAnimation {
            Anim {
                target: loader
                property: "opacity"
                from: 0
                to: 1
                type: Anim.SlowEffects
            }
            Anim {
                target: loader.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                type: Anim.SlowEffects
            }
        }
    }

    Component {
        id: placeholderComp

        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.padding.extraSmall

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "handyman"
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Page under construction")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.title.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("This page will be available in a future update.")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.body.large
                }
            }
        }
    }
}
