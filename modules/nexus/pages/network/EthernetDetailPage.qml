pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Detail / settings sub-page for an ethernet device. Reached by tapping an
// ethernet row on NetworkPage.
PageBase {
    id: root

    readonly property string ifaceName: nState.selectedEthernetInterface
    readonly property Nmcli.EthernetDevice device: Nmcli.ethernetDevices.find(d => d.iface === root.ifaceName) ?? null
    readonly property var details: Nmcli.ethernetDeviceDetails
    property string activeConnectionName: root.device?.connection ?? ""
    readonly property string connectionName: (root.device?.connection && root.device.connection.length > 0) ? root.device.connection : activeConnectionName

    // Locally-edited IPv4 form state.
    property string ipMethod: "auto" // "auto" | "auto-dns" | "manual"
    property bool ipLoaded: false

    // Original loaded values, so the Apply button only shows on a real change.
    property string origMethod: "auto"
    property string origAddress: ""
    property string origGateway: ""
    property string origDns: ""

    // Locally-edited IPv6 form state.
    property string ipv6Method: "auto" // "auto" | "auto-dns" | "manual" | "link-local" | "disabled"
    property bool ipv6Loaded: false

    // Original loaded values for IPv6.
    property string origIpv6Method: "auto"
    property string origIpv6Address: ""
    property string origIpv6Gateway: ""
    property string origIpv6Dns: ""

    property bool savingConfig: false

    readonly property bool hasIpv4Changes: root.ipLoaded && (
        root.ipMethod !== root.origMethod ||
        (root.ipMethod === "manual" && (addressField.text.trim() !== root.origAddress || gatewayField.text.trim() !== root.origGateway)) ||
        ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && dnsField.text.trim() !== root.origDns)
    )

    readonly property bool hasIpv6Changes: root.ipv6Loaded && (
        root.ipv6Method !== root.origIpv6Method ||
        (root.ipv6Method === "manual" && (addressFieldIpv6.text.trim() !== root.origIpv6Address || gatewayFieldIpv6.text.trim() !== root.origIpv6Gateway)) ||
        ((root.ipv6Method === "manual" || root.ipv6Method === "auto-dns") && dnsFieldIpv6.text.trim() !== root.origIpv6Dns)
    )

    readonly property bool hasChanges: root.hasIpv4Changes || root.hasIpv6Changes

    function loadIpConfig(): void {
        if (!root.connectionName)
            return;
        Nmcli.getIpv4Config(root.connectionName, cfg => {
            if (!cfg)
                return;
            root.ipMethod = cfg.method;
            methodSelect.active = cfg.method === "manual" ? manualItem : (cfg.method === "auto-dns" ? autoDnsItem : autoItem);
            addressField.text = cfg.address;
            gatewayField.text = cfg.gateway;
            dnsField.text = cfg.dns;
            root.origMethod = cfg.method;
            root.origAddress = cfg.address;
            root.origGateway = cfg.gateway;
            root.origDns = cfg.dns;
            root.ipLoaded = true;
        });
    }

    function loadIpv6Config(): void {
        if (!root.connectionName)
            return;
        Nmcli.getIpv6Config(root.connectionName, cfg => {
            if (!cfg)
                return;
            root.ipv6Method = cfg.method;
            methodSelectIpv6.active = cfg.method === "manual" ? manualItemIpv6 : (
                cfg.method === "auto-dns" ? autoDnsItemIpv6 : (
                    cfg.method === "link-local" ? linkLocalItemIpv6 : (
                        cfg.method === "disabled" ? disabledItemIpv6 : autoItemIpv6
                    )
                )
            );
            addressFieldIpv6.text = cfg.address;
            gatewayFieldIpv6.text = cfg.gateway;
            dnsFieldIpv6.text = cfg.dns;
            root.origIpv6Method = cfg.method;
            root.origIpv6Address = cfg.address;
            root.origIpv6Gateway = cfg.gateway;
            root.origIpv6Dns = cfg.dns;
            root.ipv6Loaded = true;
        });
    }

    function saveIpConfig(): void {
        if (!root.connectionName)
            return;

        // Validation for IPv4
        if (root.hasIpv4Changes) {
            if (root.ipMethod === "manual") {
                if (!addressField.valid) {
                    addressField.isError = true;
                    return;
                }
                if (!gatewayField.valid) {
                    gatewayField.isError = true;
                    return;
                }
            }
            if ((root.ipMethod === "manual" || root.ipMethod === "auto-dns") && !dnsField.valid) {
                dnsField.isError = true;
                return;
            }
        }

        // Validation for IPv6
        if (root.hasIpv6Changes) {
            if (root.ipv6Method === "manual") {
                if (!addressFieldIpv6.valid) {
                    addressFieldIpv6.isError = true;
                    return;
                }
                if (!gatewayFieldIpv6.valid) {
                    gatewayFieldIpv6.isError = true;
                    return;
                }
            }
            if ((root.ipv6Method === "manual" || root.ipv6Method === "auto-dns") && !dnsFieldIpv6.valid) {
                dnsFieldIpv6.isError = true;
                return;
            }
        }

        root.savingConfig = true;

        const saveIpv6 = () => {
            if (!root.hasIpv6Changes) {
                root.savingConfig = false;
                return;
            }
            Nmcli.setIpv6Config(root.connectionName, {
                method: root.ipv6Method,
                address: addressFieldIpv6.text.trim(),
                gateway: gatewayFieldIpv6.text.trim(),
                dns: dnsFieldIpv6.text.trim()
            }, result => {
                root.savingConfig = false;
                if (!(result && result.success)) {
                    if (root.ipv6Method === "manual")
                        addressFieldIpv6.isError = true;
                    else
                        dnsFieldIpv6.isError = true;
                } else {
                    root.origIpv6Method = root.ipv6Method;
                    root.origIpv6Address = addressFieldIpv6.text.trim();
                    root.origIpv6Gateway = gatewayFieldIpv6.text.trim();
                    root.origIpv6Dns = dnsFieldIpv6.text.trim();
                }
            });
        };

        if (root.hasIpv4Changes) {
            Nmcli.setIpv4Config(root.connectionName, {
                method: root.ipMethod,
                address: addressField.text.trim(),
                gateway: gatewayField.text.trim(),
                dns: dnsField.text.trim()
            }, result => {
                if (!(result && result.success)) {
                    root.savingConfig = false;
                    if (root.ipMethod === "manual")
                        addressField.isError = true;
                    else
                        dnsField.isError = true;
                } else {
                    root.origMethod = root.ipMethod;
                    root.origAddress = addressField.text.trim();
                    root.origGateway = gatewayField.text.trim();
                    root.origDns = dnsField.text.trim();
                    saveIpv6();
                }
            });
        } else {
            saveIpv6();
        }
    }

    title: root.device?.connection || root.activeConnectionName || root.ifaceName || Tr.tr("Ethernet")
    isSubPage: true

    Component.onCompleted: {
        Nmcli.getEthernetDeviceDetails(root.ifaceName, () => {});
        Nmcli.getEthernetSpeed(root.ifaceName);
        Nmcli.ensureEthernetConnection(root.ifaceName, conName => {
            if (conName) {
                root.activeConnectionName = conName;
                loadIpConfig();
                loadIpv6Config();
            }
        });
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Action button --------------------------------------------------
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.5)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: connectBtn

                fillWidth: true
                shapeMorph: true
                isRound: true
                enabled: root.device?.state !== "unavailable"
                inactiveColour: root.device?.connected ? Colours.palette.m3primaryContainer : Colours.palette.m3secondaryContainer
                inactiveOnColour: root.device?.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer

                implicitWidth: connectLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    if (root.device?.connected)
                        Nmcli.disconnectEthernet(root.connectionName);
                    else
                        Nmcli.connectEthernet(root.connectionName, root.ifaceName);
                }

                ColumnLayout {
                    id: connectLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.device?.connected ? "link_off" : "link"
                        color: connectBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.device?.connected ? Tr.tr("Disconnect") : Tr.tr("Connect")
                        color: connectBtn.onColour
                    }
                }
            }
        }

        // ---- Connection info ------------------------------------------------
        SectionHeader {
            first: true
            text: Tr.tr("Connection")
        }

        InfoRow {
            first: true
            icon: "link"
            label: Tr.tr("Status")
            value: root.device?.connected ? Tr.trCtx("Connected", "ethernet link state") : Tr.trCtx("Not connected", "ethernet link state")
        }

        InfoRow {
            icon: "settings_ethernet"
            label: Tr.trCtx("Interface", "network interface")
            value: root.ifaceName || "—"
        }

        InfoRow {
            icon: "speed"
            label: Tr.tr("Speed")
            visible: Nmcli.ethernetSpeed.length > 0
            value: Nmcli.ethernetSpeed
        }

        InfoRow {
            icon: "lan"
            label: Tr.tr("IP address")
            value: root.details?.ipAddress || "—"
        }

        InfoRow {
            icon: "router"
            label: Tr.tr("Gateway")
            visible: (root.details?.gateway ?? "").length > 0
            value: root.details?.gateway || "—"
        }

        InfoRow {
            icon: "lan"
            label: Tr.tr("IPv6 address")
            visible: (root.details?.ipv6Address ?? "").length > 0
            value: root.details?.ipv6Address || "—"
        }

        InfoRow {
            icon: "router"
            label: Tr.tr("IPv6 gateway")
            visible: (root.details?.ipv6Gateway ?? "").length > 0
            value: root.details?.ipv6Gateway || "—"
        }

        InfoRow {
            last: true
            icon: "memory"
            label: Tr.tr("MAC address")
            value: root.details?.macAddress || "—"
        }

        // ---- IPv4 ------------------------------------------------------------
        SectionHeader {
            text: Tr.tr("IPv4")
        }

        SelectRow {
            id: methodSelect

            Layout.fillWidth: true
            first: true
            last: root.ipMethod === "auto"
            label: Tr.tr("IP assignment")
            fallbackText: Tr.tr("Automatic (DHCP)")
            fallbackIcon: "lan"

            menuItems: [autoItem, autoDnsItem, manualItem]

            onSelected: item => root.ipMethod = item === manualItem ? "manual" : (item === autoDnsItem ? "auto-dns" : "auto")

            MenuItem {
                id: autoItem

                icon: "lan"
                text: Tr.tr("Automatic (DHCP)")
            }

            MenuItem {
                id: autoDnsItem

                icon: "dns"
                text: Tr.tr("Automatic, DNS only")
            }

            MenuItem {
                id: manualItem

                icon: "edit"
                text: Tr.trCtx("Manual", "ip configuration method")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large
            visible: root.ipMethod === "manual" || root.ipMethod === "auto-dns"

            StyledTextField {
                id: addressField

                Layout.fillWidth: true
                visible: root.ipMethod === "manual"
                placeholderText: Tr.tr("Address (CIDR)")
                leadingIcon: "router"
                supportingText: Tr.tr("IP and prefix, e.g. 192.168.1.50/24")
                errorText: Tr.tr("Enter a valid address in CIDR notation")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\/(?:3[0-2]|[12]?\d)$/
            }

            StyledTextField {
                id: gatewayField

                Layout.fillWidth: true
                visible: root.ipMethod === "manual"
                placeholderText: Tr.tr("Gateway")
                leadingIcon: "exit_to_app"
                errorText: Tr.tr("Enter a valid gateway address")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^$|^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/
            }

            StyledTextField {
                id: dnsField

                Layout.fillWidth: true
                placeholderText: Tr.tr("DNS servers")
                leadingIcon: "dns"
                supportingText: Tr.tr("Comma-separated")
                errorText: Tr.tr("Enter valid DNS server addresses")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^$|^\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\s*,\s*(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d))*\s*$/
            }
        }

        // ---- IPv6 ------------------------------------------------------------
        SectionHeader {
            text: Tr.tr("IPv6")
        }

        SelectRow {
            id: methodSelectIpv6

            Layout.fillWidth: true
            first: true
            last: root.ipv6Method === "auto" || root.ipv6Method === "link-local" || root.ipv6Method === "disabled"
            label: Tr.tr("IPv6 assignment")
            fallbackText: Tr.tr("Automatic (SLAAC/DHCPv6)")
            fallbackIcon: "lan"

            menuItems: [autoItemIpv6, autoDnsItemIpv6, manualItemIpv6, linkLocalItemIpv6, disabledItemIpv6]

            onSelected: item => {
                if (item === manualItemIpv6)
                    root.ipv6Method = "manual";
                else if (item === autoDnsItemIpv6)
                    root.ipv6Method = "auto-dns";
                else if (item === linkLocalItemIpv6)
                    root.ipv6Method = "link-local";
                else if (item === disabledItemIpv6)
                    root.ipv6Method = "disabled";
                else
                    root.ipv6Method = "auto";
            }

            MenuItem {
                id: autoItemIpv6

                icon: "lan"
                text: Tr.tr("Automatic (SLAAC/DHCPv6)")
            }

            MenuItem {
                id: autoDnsItemIpv6

                icon: "dns"
                text: Tr.tr("Automatic, DNS only")
            }

            MenuItem {
                id: manualItemIpv6

                icon: "edit"
                text: Tr.trCtx("Manual", "ip configuration method")
            }

            MenuItem {
                id: linkLocalItemIpv6

                icon: "settings_ethernet"
                text: Tr.tr("Link-Local Only")
            }

            MenuItem {
                id: disabledItemIpv6

                icon: "block"
                text: Tr.tr("Disabled")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large
            visible: root.ipv6Method === "manual" || root.ipv6Method === "auto-dns"

            StyledTextField {
                id: addressFieldIpv6

                Layout.fillWidth: true
                visible: root.ipv6Method === "manual"
                placeholderText: Tr.tr("IPv6 Address (CIDR)")
                leadingIcon: "router"
                supportingText: Tr.tr("IPv6 and prefix, e.g. 2001:db8::1/64")
                errorText: Tr.tr("Enter a valid IPv6 address in CIDR notation")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))\/(12[0-8]|1[01]\d|[1-9]?\d)$/
            }

            StyledTextField {
                id: gatewayFieldIpv6

                Layout.fillWidth: true
                visible: root.ipv6Method === "manual"
                placeholderText: Tr.tr("IPv6 Gateway")
                leadingIcon: "exit_to_app"
                errorText: Tr.tr("Enter a valid IPv6 gateway address")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: /^$|^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/
            }

            StyledTextField {
                id: dnsFieldIpv6

                Layout.fillWidth: true
                placeholderText: Tr.tr("IPv6 DNS servers")
                leadingIcon: "dns"
                supportingText: Tr.tr("Comma-separated IPv6 addresses")
                errorText: Tr.tr("Enter valid IPv6 DNS server addresses")
                inputMethodHints: Qt.ImhNoPredictiveText
                validate: text => {
                    const trimmed = (text || "").trim();
                    if (!trimmed) return true;
                    const parts = trimmed.split(",");
                    const ipRegex = /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/;
                    return parts.every(p => ipRegex.test(p.trim()));
                }
            }
        }

        // Apply button — swaps to a loading spinner while applying. Shown only
        // when the IP assignment has unsaved changes.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.medium
            visible: root.hasChanges || root.savingConfig

            Item {
                Layout.fillWidth: true
            }

            ButtonBase {
                id: applyBtn

                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primary
                inactiveOnColour: Colours.palette.m3onPrimary
                stateLayer.disabled: (!root.ipLoaded && !root.ipv6Loaded) || root.savingConfig

                implicitWidth: applyContent.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: applyContent.implicitHeight + Tokens.padding.medium * 2

                onClicked: if ((root.ipLoaded || root.ipv6Loaded) && !root.savingConfig)
                    root.saveIpConfig()

                AnimLoader {
                    id: applyContent

                    anchors.centerIn: parent
                    sourceComp: root.savingConfig ? applyLoadingComp : applyTextComp
                    outAnimType: Anim.SlowEffects
                    inAnimType: Anim.SlowEffects
                }

                Component {
                    id: applyLoadingComp

                    LoadingIndicator {
                        implicitSize: Math.round(Tokens.font.body.medium.pointSize * 1.4)
                        color: applyBtn.onColour
                    }
                }

                Component {
                    id: applyTextComp

                    StyledText {
                        text: Tr.tr("Apply")
                        color: applyBtn.onColour
                        animate: true
                    }
                }
            }
        }
    }
}
