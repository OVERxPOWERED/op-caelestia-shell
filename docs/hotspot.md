# 📶 Wi-Fi Hotspot & Tethering

Caelestia includes native support for Wi-Fi Access Point (Hotspot) broadcasting and tethering management powered by NetworkManager.

---

## 🌟 Features

- **1-Click Quick Toggle**: Enable or disable Hotspot broadcasting directly from the Dashboard Quick Toggles.
- **Top Bar Status Indicator**: A dedicated dynamic status icon (`wifi_tethering`) illuminates in the bar when active and automatically hides when idle.
- **Nexus Settings Subpage**: Manage Hotspot name (SSID), WPA2/WPA3 password, and frequency bands.
- **Dual-Band Support**: Switch between **2.4 GHz** (long range / maximum device compatibility) and **5 GHz** (high speed).
- **Connected Clients Monitor**: Live device list showing assigned IP addresses, MAC addresses, and active connection status.
- **Desktop Toasts**: Live system notifications when hotspot broadcasting starts, stops, or changes credentials.

---

## 🎮 How to Use

### 1. Toggle via Dashboard
1. Open the Dashboard (`Super + D` or click the dashboard icon).
2. Click the **Wi-Fi Hotspot** tile (`wifi_tethering`).
3. The tile will illuminate, and a toast will confirm that your hotspot is now broadcasting.

### 2. Configure Credentials via Nexus Settings
1. Open **Nexus Settings** (`Super + I` or via Launcher/Dashboard).
2. Navigate to **Connectivity $\rightarrow$ Network**.
3. Under **Hotspot & Tethering**, click **Hotspot settings**.
4. Adjust your network settings:
   - **Hotspot Network Name (SSID)**: e.g. `My-Custom-Hotspot`
   - **Password**: At least 8 characters (click the eye icon to reveal plaintext).
   - **Frequency Band**: Choose `2.4 GHz` or `5 GHz`.
5. Click **Save & Apply**. If the hotspot is currently broadcasting, it will automatically restart with the new credentials.

---

## ⚙️ Configuration Schema (`shell.json`)

The default hotspot preferences are persisted in NetworkManager and can be customized via `~/.config/caelestia/shell.json`:

```json
{
  "utilities": {
    "quickToggles": [
      { "id": "wifi", "enabled": true },
      { "id": "bluetooth", "enabled": true },
      { "id": "mic", "enabled": true },
      { "id": "settings", "enabled": true },
      { "id": "gameMode", "enabled": true },
      { "id": "dnd", "enabled": true },
      { "id": "vpn", "enabled": false },
      { "id": "hotspot", "enabled": true }
    ]
  }
}
```

---

## 🔧 Hardware Requirements & Troubleshooting

### Check AP Mode Support
Most modern Wi-Fi adapters (Intel, Realtek, Atheros, Broadcom) support Access Point mode. You can verify your wireless card with:
```sh
iw list | grep -A 8 "Supported interface modes"
```
Ensure **`AP`** is listed under supported interface modes.

### Terminal Control
You can also manage the hotspot directly via NetworkManager CLI:
- **Start**: `nmcli device wifi hotspot ssid <SSID> password <Password>`
- **Stop**: `nmcli connection down Hotspot`
- **Clients**: `ip -j neigh show dev <interface>`
