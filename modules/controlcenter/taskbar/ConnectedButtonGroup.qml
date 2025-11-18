import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property var options: [] // Array of {label: string, propertyName: string, onToggled: function}
    property var rootItem: null // The root item that contains the properties we want to bind to
    property string title: "" // Optional title text

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            visible: root.title !== ""
            text: root.title
            font.pointSize: Appearance.font.size.normal
        }

        RowLayout {
            id: buttonRow
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            Repeater {
                id: repeater
                model: root.options

                delegate: TextButton {
                    id: button
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.label
                    
                    property bool isChecked: false
                    
                    // Initialize from root property
                    Component.onCompleted: {
                        if (root.rootItem && modelData.propertyName) {
                            isChecked = root.rootItem[modelData.propertyName];
                        }
                    }
                    
                    checked: isChecked
                    toggle: false
                    type: TextButton.Tonal

                    // Listen for property changes on rootItem
                    Connections {
                        target: root.rootItem
                        enabled: root.rootItem !== null && modelData.propertyName !== undefined

                        function onShowAudioChanged() {
                            if (modelData.propertyName === "showAudio") {
                                button.isChecked = root.rootItem.showAudio;
                            }
                        }

                        function onShowMicrophoneChanged() {
                            if (modelData.propertyName === "showMicrophone") {
                                button.isChecked = root.rootItem.showMicrophone;
                            }
                        }

                        function onShowKbLayoutChanged() {
                            if (modelData.propertyName === "showKbLayout") {
                                button.isChecked = root.rootItem.showKbLayout;
                            }
                        }

                        function onShowNetworkChanged() {
                            if (modelData.propertyName === "showNetwork") {
                                button.isChecked = root.rootItem.showNetwork;
                            }
                        }

                        function onShowBluetoothChanged() {
                            if (modelData.propertyName === "showBluetooth") {
                                button.isChecked = root.rootItem.showBluetooth;
                            }
                        }

                        function onShowBatteryChanged() {
                            if (modelData.propertyName === "showBattery") {
                                button.isChecked = root.rootItem.showBattery;
                            }
                        }

                        function onShowLockStatusChanged() {
                            if (modelData.propertyName === "showLockStatus") {
                                button.isChecked = root.rootItem.showLockStatus;
                            }
                        }

                        function onTrayBackgroundChanged() {
                            if (modelData.propertyName === "trayBackground") {
                                button.isChecked = root.rootItem.trayBackground;
                            }
                        }

                        function onTrayCompactChanged() {
                            if (modelData.propertyName === "trayCompact") {
                                button.isChecked = root.rootItem.trayCompact;
                            }
                        }

                        function onTrayRecolourChanged() {
                            if (modelData.propertyName === "trayRecolour") {
                                button.isChecked = root.rootItem.trayRecolour;
                            }
                        }

                        function onScrollWorkspacesChanged() {
                            if (modelData.propertyName === "scrollWorkspaces") {
                                button.isChecked = root.rootItem.scrollWorkspaces;
                            }
                        }

                        function onScrollVolumeChanged() {
                            if (modelData.propertyName === "scrollVolume") {
                                button.isChecked = root.rootItem.scrollVolume;
                            }
                        }

                        function onScrollBrightnessChanged() {
                            if (modelData.propertyName === "scrollBrightness") {
                                button.isChecked = root.rootItem.scrollBrightness;
                            }
                        }
                    }

                    // Match utilities Toggles radius styling
                    // Each button has full rounding (not connected) since they have spacing
                    radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : Appearance.rounding.normal

                    // Match utilities Toggles inactive color
                    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                    
                    // Adjust width similar to utilities toggles
                    Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.large : internalChecked ? Appearance.padding.smaller : 0)

                    onClicked: {
                        if (modelData.onToggled) {
                            modelData.onToggled(!checked);
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }

                    Behavior on radius {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                }
            }
        }
    }
}

