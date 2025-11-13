# Nmcli.qml Feature Completion Plan

This document outlines the missing features needed in `Nmcli.qml` to replace `Network.qml` or rewrite the wireless panel in the control center.

## Current Status

`Nmcli.qml` currently has:
- ✅ Device status queries
- ✅ Wireless/Ethernet interface listing
- ✅ Interface connection status checking
- ✅ Basic wireless connection (SSID + password)
- ✅ Disconnect functionality
- ✅ Device details (basic)
- ✅ Interface up/down
- ✅ WiFi scanning
- ✅ SSID listing with signal/security (sorted)

## Missing Features

### 1. WiFi Radio Control
- [x] `enableWifi(enabled: bool)` - Turn WiFi radio on/off
- [x] `toggleWifi()` - Toggle WiFi radio state
- [x] `wifiEnabled` property - Current WiFi radio state
- [x] Monitor WiFi radio state changes

**Implementation Notes:**
- Use `nmcli radio wifi on/off`
- Monitor state with `nmcli radio wifi`
- Update `wifiEnabled` property on state changes

### 2. Network List Management
- [x] `networks` property - List of AccessPoint objects
- [x] `active` property - Currently active network
- [x] Real-time network list updates
- [x] Network grouping by SSID with signal prioritization
- [x] AccessPoint component/object with properties:
  - `ssid`, `bssid`, `strength`, `frequency`, `active`, `security`, `isSecure`

**Implementation Notes:**
- Use `nmcli -g ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY d w`
- Parse and group networks by SSID
- Prioritize active/connected networks
- Update network list on connection changes

### 3. Connection Management - BSSID Support
- [x] BSSID support in `connectWireless()` function
- [x] Connection profile creation with BSSID (`createConnectionWithPassword`)
- [x] Handle BSSID in connection commands

**Implementation Notes:**
- Use `nmcli connection add` with `802-11-wireless.bssid` for BSSID-based connections
- Fallback to SSID-only connection if BSSID not available
- Handle existing connection profiles when BSSID is provided

### 4. Saved Connection Profile Management
- [x] `savedConnections` property - List of saved connection names
- [x] `savedConnectionSsids` property - List of saved SSIDs
- [x] `hasSavedProfile(ssid: string)` function - Check if profile exists
- [x] `forgetNetwork(ssid: string)` function - Delete connection profile
- [x] Load saved connections on startup
- [x] Update saved connections list after connection changes

**Implementation Notes:**
- Use `nmcli -t -f NAME,TYPE connection show` to list connections
- Query SSIDs for WiFi connections: `nmcli -t -f 802-11-wireless.ssid connection show <name>`
- Use `nmcli connection delete <name>` to forget networks
- Case-insensitive SSID matching

### 5. Pending Connection Tracking
- [x] `pendingConnection` property - Track connection in progress
- [x] Connection state tracking with timers
- [x] Connection success/failure detection
- [x] Automatic retry or callback on failure

**Implementation Notes:**
- Track pending connection with SSID/BSSID
- Use timers to check connection status
- Monitor network list updates to detect successful connection
- Handle connection failures and trigger callbacks

### 6. Connection Failure Handling
- [x] `connectionFailed(ssid: string)` signal
- [x] Password requirement detection from error messages
- [x] Connection retry logic
- [x] Error message parsing and reporting

**Implementation Notes:**
- Parse stderr output for password requirements
- Detect specific error patterns (e.g., "Secrets were required")
- Emit signals for UI to handle password dialogs
- Provide meaningful error messages

### 7. Password Callback Handling
- [x] `connectToNetworkWithPasswordCheck()` function
- [x] Try connection without password first (use saved password)
- [x] Callback on password requirement
- [x] Handle both secure and open networks

**Implementation Notes:**
- Attempt connection without password for secure networks
- If connection fails with password error, trigger callback
- For open networks, connect directly
- Support callback pattern for password dialogs

### 8. Device Details Parsing
- [x] Full parsing of `device show` output
- [x] `wirelessDeviceDetails` property with:
  - `ipAddress`, `gateway`, `dns[]`, `subnet`, `macAddress`
- [x] `ethernetDeviceDetails` property with:
  - `ipAddress`, `gateway`, `dns[]`, `subnet`, `macAddress`, `speed`
- [x] `cidrToSubnetMask()` helper function
- [x] Update device details on connection changes

**Implementation Notes:**
- Parse `nmcli device show <interface>` output
- Extract IP4.ADDRESS, IP4.GATEWAY, IP4.DNS, etc.
- Convert CIDR notation to subnet mask
- Handle both wireless and ethernet device details

### 9. Connection Status Monitoring
- [x] Automatic network list refresh on connection changes
- [x] Monitor connection state changes
- [x] Update active network property
- [x] Refresh device details on connection

**Implementation Notes:**
- Use Process stdout SplitParser to monitor changes
- Trigger network list refresh on connection events
- Update `active` property when connection changes
- Refresh device details when connected

### 10. Ethernet Device Management
- [x] `ethernetDevices` property - List of ethernet devices
- [x] `activeEthernet` property - Currently active ethernet device
- [x] `connectEthernet(connectionName, interfaceName)` function
- [x] `disconnectEthernet(connectionName)` function
- [x] Ethernet device details parsing
