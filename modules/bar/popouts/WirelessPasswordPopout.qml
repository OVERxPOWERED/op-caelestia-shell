pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper
    property var network: null
    property bool isClosing: false

    readonly property bool shouldBeVisible: root.wrapper.currentName === "wirelesspassword"

    Connections {
        target: root.wrapper
        function onCurrentNameChanged() {
            if (root.wrapper.currentName === "wirelesspassword") {
                // Update network when popout becomes active
                Qt.callLater(() => {
                    // Try to get network from parent Content's networkPopout
                    const content = root.parent?.parent?.parent;
                    if (content) {
                        const networkPopout = content.children.find(c => c.name === "network");
                        if (networkPopout && networkPopout.item) {
                            root.network = networkPopout.item.passwordNetwork;
                        }
                    }
                    // Force focus to password container when popout becomes active
                    Qt.callLater(() => {
                        passwordContainer.forceActiveFocus();
                    }, 100);
                }, 100);
            }
        }
    }

    spacing: Appearance.spacing.normal
    
    implicitWidth: 400
    implicitHeight: content.implicitHeight + Appearance.padding.large * 2

    visible: shouldBeVisible || isClosing
    enabled: shouldBeVisible && !isClosing
    focus: enabled
    
    Component.onCompleted: {
        if (shouldBeVisible) {
            Qt.callLater(() => {
                root.forceActiveFocus();
                passwordContainer.forceActiveFocus();
            }, 150);
        }
    }
    
    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            Qt.callLater(() => {
                root.forceActiveFocus();
                passwordContainer.forceActiveFocus();
            }, 150);
        }
    }

    Keys.onEscapePressed: {
        closeDialog();
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredWidth: 400
        implicitHeight: content.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surface
        opacity: root.shouldBeVisible && !root.isClosing ? 1 : 0
        scale: root.shouldBeVisible && !root.isClosing ? 1 : 0.7

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        ParallelAnimation {
            running: root.isClosing
            onFinished: {
                if (root.isClosing) {
                    root.isClosing = false;
                }
            }

            Anim {
                target: parent
                property: "opacity"
                to: 0
            }
            Anim {
                target: parent
                property: "scale"
                to: 0.7
            }
        }

        Keys.onEscapePressed: closeDialog();

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                font.pointSize: Appearance.font.size.extraLarge * 2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enter password")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                id: networkNameText
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (root.network) {
                        const ssid = root.network.ssid;
                        if (ssid && ssid.length > 0) {
                            return qsTr("Network: %1").arg(ssid);
                        }
                    }
                    return qsTr("Network: Unknown");
                }
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
            
            Timer {
                interval: 50
                running: root.shouldBeVisible && (!root.network || !root.network.ssid)
                repeat: true
                property int attempts: 0
                onTriggered: {
                    attempts++;
                    // Keep trying to get network from Network component
                    const content = root.parent?.parent?.parent;
                    if (content) {
                        const networkPopout = content.children.find(c => c.name === "network");
                        if (networkPopout && networkPopout.item && networkPopout.item.passwordNetwork) {
                            root.network = networkPopout.item.passwordNetwork;
                        }
                    }
                    // Stop if we got it or after 20 attempts (1 second)
                    if ((root.network && root.network.ssid) || attempts >= 20) {
                        stop();
                        attempts = 0;
                    }
                }
                onRunningChanged: {
                    if (!running) {
                        attempts = 0;
                    }
                }
            }

            StyledText {
                id: statusText

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                visible: connectButton.connecting || connectButton.hasError
                text: {
                    if (connectButton.hasError) {
                        return qsTr("Connection failed. Please check your password and try again.");
                    }
                    if (connectButton.connecting) {
                        return qsTr("Connecting...");
                    }
                    return "";
                }
                color: connectButton.hasError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                font.weight: 400
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width - Appearance.padding.large * 2
            }

            FocusScope {
                id: passwordContainer
                objectName: "passwordContainer"
                Layout.topMargin: Appearance.spacing.large
                Layout.fillWidth: true
                implicitHeight: Math.max(48, charList.implicitHeight + Appearance.padding.normal * 2)

                focus: true
                activeFocusOnTab: true

                property string passwordBuffer: ""

                Keys.onPressed: event => {
                    // Ensure we have focus when receiving keyboard input
                    if (!activeFocus) {
                        forceActiveFocus();
                    }
                    
                    // Clear error when user starts typing
                    if (connectButton.hasError && event.text && event.text.length > 0) {
                        connectButton.hasError = false;
                    }
                    
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        if (connectButton.enabled) {
                            connectButton.clicked();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace) {
                        if (event.modifiers & Qt.ControlModifier) {
                            passwordBuffer = "";
                        } else {
                            passwordBuffer = passwordBuffer.slice(0, -1);
                        }
                        event.accepted = true;
                    } else if (event.text && event.text.length > 0) {
                        passwordBuffer += event.text;
                        event.accepted = true;
                    }
                }

                Connections {
                    target: root
                    function onShouldBeVisibleChanged(): void {
                        if (root.shouldBeVisible) {
                            Qt.callLater(() => {
                                passwordContainer.forceActiveFocus();
                            }, 50);
                            passwordContainer.passwordBuffer = "";
                            connectButton.hasError = false;
                        }
                    }
                }
                
                Component.onCompleted: {
                    if (root.shouldBeVisible) {
                        Qt.callLater(() => {
                            passwordContainer.forceActiveFocus();
                        }, 100);
                    }
                }

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: passwordContainer.activeFocus 
                        ? Qt.lighter(Colours.tPalette.m3surfaceContainer, 1.05)
                        : Colours.tPalette.m3surfaceContainer
                    border.width: passwordContainer.activeFocus || connectButton.hasError ? 4 : (root.shouldBeVisible ? 1 : 0)
                    border.color: {
                        if (connectButton.hasError) {
                            return Colours.palette.m3error;
                        }
                        if (passwordContainer.activeFocus) {
                            return Colours.palette.m3primary;
                        }
                        return root.shouldBeVisible ? Colours.palette.m3outline : "transparent";
                    }

                    Behavior on border.color {
                        CAnim {}
                    }

                    Behavior on border.width {
                        CAnim {}
                    }

                    Behavior on color {
                        CAnim {}
                    }
                }

                StateLayer {
                    hoverEnabled: false
                    cursorShape: Qt.IBeamCursor
                    radius: Appearance.rounding.normal

                    function onClicked(): void {
                        passwordContainer.forceActiveFocus();
                    }
                }

                StyledText {
                    id: placeholder

                    anchors.centerIn: parent
                    text: qsTr("Password")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.mono
                    opacity: passwordContainer.passwordBuffer ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }

                ListView {
                    id: charList

                    readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

                    anchors.centerIn: parent
                    implicitWidth: fullWidth
                    implicitHeight: Appearance.font.size.normal

                    orientation: Qt.Horizontal
                    spacing: Appearance.spacing.small / 2
                    interactive: false

                    model: ScriptModel {
                        values: passwordContainer.passwordBuffer.split("")
                    }

                    delegate: StyledRect {
                        id: ch

                        implicitWidth: implicitHeight
                        implicitHeight: charList.implicitHeight

                        color: Colours.palette.m3onSurface
                        radius: Appearance.rounding.small / 2

                        opacity: 0
                        scale: 0
                        Component.onCompleted: {
                            opacity = 1;
                            scale = 1;
                        }
                        ListView.onRemove: removeAnim.start()

                        SequentialAnimation {
                            id: removeAnim

                            PropertyAction {
                                target: ch
                                property: "ListView.delayRemove"
                                value: true
                            }
                            ParallelAnimation {
                                Anim {
                                    target: ch
                                    property: "opacity"
                                    to: 0
                                }
                                Anim {
                                    target: ch
                                    property: "scale"
                                    to: 0.5
                                }
                            }
                            PropertyAction {
                                target: ch
                                property: "ListView.delayRemove"
                                value: false
                            }
                        }

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                duration: Appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            }
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }
                }
            }

            RowLayout {
                Layout.topMargin: Appearance.spacing.normal
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                SimpleButton {
                    id: cancelButton

                    Layout.fillWidth: true
                    Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Cancel")

                    onClicked: closeDialog();
                }

                SimpleButton {
                    id: connectButton

                    Layout.fillWidth: true
                    Layout.minimumHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
                    color: Colours.palette.m3primary
                    onColor: Colours.palette.m3onPrimary
                    text: qsTr("Connect")
                    enabled: passwordContainer.passwordBuffer.length > 0 && !connecting

                    property bool connecting: false
                    property bool hasError: false

                    onClicked: {
                        if (!root.network || connecting) {
                            return;
                        }

                        const password = passwordContainer.passwordBuffer;
                        if (!password || password.length === 0) {
                            return;
                        }

                        // Clear any previous error
                        hasError = false;

                        // Set connecting state
                        connecting = true;
                        enabled = false;
                        text = qsTr("Connecting...");

                        // Connect to network
                        Nmcli.connectToNetwork(
                            root.network.ssid,
                            password,
                            root.network.bssid || "",
                            (result) => {
                                if (result && result.success) {
                                    // Connection successful, monitor will handle the rest
                                } else if (result && result.needsPassword) {
                                    // Shouldn't happen since we provided password
                                    connectionMonitor.stop();
                                    connecting = false;
                                    hasError = true;
                                    enabled = true;
                                    text = qsTr("Connect");
                                    passwordContainer.passwordBuffer = "";
                                    // Delete the failed connection
                                    if (root.network && root.network.ssid) {
                                        Nmcli.forgetNetwork(root.network.ssid, () => {});
                                    }
                                } else {
                                    // Connection failed immediately - show error
                                    connectionMonitor.stop();
                                    connecting = false;
                                    hasError = true;
                                    enabled = true;
                                    text = qsTr("Connect");
                                    passwordContainer.passwordBuffer = "";
                                    // Delete the failed connection
                                    if (root.network && root.network.ssid) {
                                        Nmcli.forgetNetwork(root.network.ssid, () => {});
                                    }
                                }
                            }
                        );

                        // Start monitoring connection
                        connectionMonitor.start();
                    }
                }
            }
        }
    }

    function checkConnectionStatus(): void {
        if (!root.shouldBeVisible || !connectButton.connecting) {
            return;
        }

        // Check if we're connected to the target network (case-insensitive SSID comparison)
        const isConnected = root.network && Nmcli.active && Nmcli.active.ssid &&
                           Nmcli.active.ssid.toLowerCase().trim() === root.network.ssid.toLowerCase().trim();

        if (isConnected) {
            // Successfully connected - give it a moment for network list to update
            Qt.callLater(() => {
                // Double-check connection is still active
                if (root.shouldBeVisible && Nmcli.active && Nmcli.active.ssid) {
                    const stillConnected = Nmcli.active.ssid.toLowerCase().trim() === root.network.ssid.toLowerCase().trim();
                    if (stillConnected) {
                        connectionMonitor.stop();
                        connectButton.connecting = false;
                        connectButton.text = qsTr("Connect");
                        // Return to network popout on successful connection
                        if (root.wrapper.currentName === "wirelesspassword") {
                            root.wrapper.currentName = "network";
                        }
                        closeDialog();
                    }
                }
            }, 500);
            return;
        }

        // Check for connection failures - if pending connection was cleared but we're not connected
        if (Nmcli.pendingConnection === null && connectButton.connecting) {
            // Wait a bit more before giving up (allow time for connection to establish)
            if (connectionMonitor.repeatCount > 10) {
                connectionMonitor.stop();
                connectButton.connecting = false;
                connectButton.hasError = true;
                connectButton.enabled = true;
                connectButton.text = qsTr("Connect");
                passwordContainer.passwordBuffer = "";
                // Delete the failed connection
                if (root.network && root.network.ssid) {
                    Nmcli.forgetNetwork(root.network.ssid, () => {});
                }
            }
        }
    }

    Timer {
        id: connectionMonitor
        interval: 1000
        repeat: true
        triggeredOnStart: false
        property int repeatCount: 0

        onTriggered: {
            repeatCount++;
            checkConnectionStatus();
        }

        onRunningChanged: {
            if (!running) {
                repeatCount = 0;
            }
        }
    }

    Connections {
        target: Nmcli
        function onActiveChanged() {
            if (root.shouldBeVisible) {
                checkConnectionStatus();
            }
        }
        function onConnectionFailed(ssid: string) {
            if (root.shouldBeVisible && root.network && root.network.ssid === ssid && connectButton.connecting) {
                connectionMonitor.stop();
                connectButton.connecting = false;
                connectButton.hasError = true;
                connectButton.enabled = true;
                connectButton.text = qsTr("Connect");
                passwordContainer.passwordBuffer = "";
                // Delete the failed connection
                Nmcli.forgetNetwork(ssid, () => {});
            }
        }
    }

    function closeDialog(): void {
        if (isClosing) {
            return;
        }
        
        isClosing = true;
        passwordContainer.passwordBuffer = "";
        connectButton.connecting = false;
        connectButton.hasError = false;
        connectButton.text = qsTr("Connect");
        connectionMonitor.stop();
        
        // Return to network popout
        if (root.wrapper.currentName === "wirelesspassword") {
            root.wrapper.currentName = "network";
        }
    }

    component SimpleButton: StyledRect {
        id: button

        property color onColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text
        property alias enabled: stateLayer.enabled
        property string icon: ""

        implicitWidth: rowLayout.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: rowLayout.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.small

        StateLayer {
            id: stateLayer
            color: parent.onColor
            function onClicked(): void {
                if (parent.enabled !== false) {
                    parent.clicked();
                }
            }
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                id: iconItem
                visible: button.icon.length > 0
                text: button.icon
                color: button.onColor
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                id: label
                Layout.leftMargin: button.icon.length > 0 ? Appearance.padding.smaller : 0
                color: parent.parent.onColor
            }
        }

        signal clicked
    }
}

