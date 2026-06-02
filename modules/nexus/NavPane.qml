pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: Tokens.spacing.extraSmall

    Repeater {
        id: list

        model: PageRegistry.pages

        StyledRect {
            id: item

            required property var modelData
            required property int index

            readonly property bool isCurrentPage: index === root.nState.currentPageIdx
            readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1].category !== modelData.category
            readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1].category !== modelData.category

            Layout.fillWidth: true
            Layout.topMargin: index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0
            implicitHeight: {
                const h = layout.implicitHeight + layout.anchors.margins * 2;
                return h % 2 === 0 ? h : h + 1;
            }

            color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

            topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
            bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

            RadiusBehavior on topLeftRadius {}
            RadiusBehavior on topRightRadius {}
            RadiusBehavior on bottomLeftRadius {}
            RadiusBehavior on bottomRightRadius {}

            StateLayer {
                id: stateLayer

                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius

                onClicked: root.nState.currentPageIdx = item.index
            }

            RowLayout {
                id: layout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledRect {
                    Layout.fillHeight: true
                    Layout.topMargin: -1
                    Layout.bottomMargin: -1
                    implicitWidth: height

                    radius: Tokens.rounding.full
                    color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1

                        text: item.modelData.icon
                        color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.medium
                        fill: 1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0 //Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.label
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.description
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
