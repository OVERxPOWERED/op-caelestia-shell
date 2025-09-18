pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property string modelData
    required property Props props

    readonly property list<var> notifs: Notifs.list.filter(notif => notif.appName === modelData).reverse()
    readonly property string image: notifs.find(n => n.image.length > 0)?.image ?? ""
    readonly property string appIcon: notifs.find(n => n.appIcon.length > 0)?.appIcon ?? ""
    readonly property string urgency: notifs.some(n => n.urgency === NotificationUrgency.Critical) ? "critical" : notifs.some(n => n.urgency === NotificationUrgency.Normal) ? "normal" : "low"

    readonly property bool expanded: props.expandedNotifs.includes(modelData)

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: content.implicitHeight + Appearance.padding.normal * 2

    clip: true
    radius: Appearance.rounding.normal
    color: root.urgency === "critical" ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 2)

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Appearance.padding.normal

        spacing: Appearance.spacing.normal

        Item {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            implicitWidth: Config.notifs.sizes.image
            implicitHeight: Config.notifs.sizes.image

            Component {
                id: imageComp

                Image {
                    source: Qt.resolvedUrl(root.image)
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    width: Config.notifs.sizes.image
                    height: Config.notifs.sizes.image
                }
            }

            Component {
                id: appIconComp

                ColouredIcon {
                    implicitSize: Math.round(Config.notifs.sizes.image * 0.6)
                    source: Quickshell.iconPath(root.appIcon)
                    colour: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    layer.enabled: root.appIcon.endsWith("symbolic")
                }
            }

            Component {
                id: materialIconComp

                MaterialIcon {
                    text: Icons.getNotifIcon(root.notifs[0]?.summary, root.urgency)
                    color: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                color: root.urgency === "critical" ? Colours.palette.m3error : root.urgency === "low" ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 3) : Colours.palette.m3secondaryContainer
                radius: Appearance.rounding.full

                Loader {
                    anchors.centerIn: parent
                    asynchronous: true
                    sourceComponent: root.image ? imageComp : root.appIcon ? appIconComp : materialIconComp
                }
            }

            Loader {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                asynchronous: true
                active: root.appIcon && root.image

                sourceComponent: StyledRect {
                    implicitWidth: Config.notifs.sizes.badge
                    implicitHeight: Config.notifs.sizes.badge

                    color: root.urgency === "critical" ? Colours.palette.m3error : root.urgency === "low" ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3secondaryContainer
                    radius: Appearance.rounding.full

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.notifs.sizes.badge * 0.6)
                        source: Quickshell.iconPath(root.appIcon)
                        colour: root.urgency === "critical" ? Colours.palette.m3onError : root.urgency === "low" ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer
                        layer.enabled: root.appIcon.endsWith("symbolic")
                    }
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: -Appearance.padding.small
            Layout.bottomMargin: -Appearance.padding.small / 2
            Layout.fillWidth: true
            spacing: Math.round(Appearance.spacing.small / 2)

            RowLayout {
                Layout.bottomMargin: -parent.spacing
                Layout.fillWidth: true
                spacing: Appearance.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }

                StyledText {
                    animate: true
                    text: root.notifs[0]?.timeStr ?? ""
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                StyledRect {
                    implicitWidth: expandBtn.implicitWidth + Appearance.padding.smaller * 2
                    implicitHeight: groupCount.implicitHeight + Appearance.padding.small

                    color: root.urgency === "critical" ? Colours.palette.m3error : Colours.layer(Colours.palette.m3surfaceContainerHigh, 3)
                    radius: Appearance.rounding.full

                    StateLayer {
                        color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface

                        function onClicked(): void {
                            if (root.expanded)
                                root.props.expandedNotifs.splice(root.props.expandedNotifs.indexOf(root.modelData), 1);
                            else
                                root.props.expandedNotifs.push(root.modelData);
                        }
                    }

                    RowLayout {
                        id: expandBtn

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small / 2

                        StyledText {
                            id: groupCount

                            Layout.leftMargin: Appearance.padding.small / 2
                            animate: true
                            text: root.notifs.length
                            color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.small
                        }

                        MaterialIcon {
                            Layout.rightMargin: -Appearance.padding.small / 2
                            animate: true
                            text: root.expanded ? "expand_less" : "expand_more"
                            color: root.urgency === "critical" ? Colours.palette.m3onError : Colours.palette.m3onSurface
                        }
                    }
                }
            }

            Repeater {
                id: notifList

                model: ScriptModel {
                    values: root.expanded ? root.notifs : root.notifs.slice(0, Config.notifs.groupPreviewNum)
                }

                Layout.fillWidth: true

                Notif {
                    id: notif

                    props: root.props
                    expanded: root.expanded
                }
            }
        }
    }

    // Behavior on implicitHeight {
    //     Anim {
    //         duration: Appearance.anim.durations.expressiveDefaultSpatial
    //         easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    //     }
    // }
}
