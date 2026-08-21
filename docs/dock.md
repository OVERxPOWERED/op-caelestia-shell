# 🚢 Application Dock

The **Application Dock** is a modern, floating desktop dock for Caelestia Shell that provides quick access to running and pinned applications with smooth gestures and native context menu actions.

---

## ✨ Features

- **Floating Design**: Positioned cleanly at the bottom screen edge with dynamic pill styling.
- **Running Window Indicators**: Dots and pills indicating how many instances of an application are running and which is active.
- **Pinned Applications**: Pin favorite apps for persistent one-click launching across sessions.
- **Interactive Context Menu**: Right-click any dock icon to:
  - Launch a **New Window**.
  - **Pin to Dock** / **Unpin from Dock**.
  - View and focus individual open windows.
  - Close specific windows.
- **Smart Hover Reveal & Auto-Hide**: Configurable auto-hide delay and bottom-edge hover detection.
- **Gesture Conflict Resolution**: Intelligently alternates with the App Launcher so bottom-edge hover and drag gestures never collide.

---

## 🎮 Gestures & Interactions

The Dock and Launcher share the bottom screen edge. Their gesture behaviors are coordinated:

| Launcher Setting | Bottom Screen Edge Hover | Bottom Screen Edge Drag Up |
| :--- | :--- | :--- |
| **Launcher on Hover** | Reveals the **Launcher** | Reveals the **Dock** |
| **Launcher on Drag** | Reveals the **Dock** | Reveals the **Launcher** |

*Note: Opening the Launcher automatically dismisses the Dock.*

---

## ⚙️ Configuration (`shell.json`)

To configure the dock, add the `"dock"` section to your `~/.config/caelestia/shell.json`:

```json
{
  "dock": {
    "enabled": true,
    "showOnHover": true,
    "maxSlots": 10,
    "dragThreshold": 20,
    "pinnedApps": [
      "firefox.desktop",
      "thunar.desktop",
      "foot.desktop"
    ]
  }
}
```

### Options Reference

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enabled` | `boolean` | `true` | Enable or disable the dock globally. |
| `showOnHover` | `boolean` | `true` | Reveal dock when cursor touches the bottom screen edge. If false, dock opens via drag. |
| `maxSlots` | `integer` | `10` | Maximum number of application icons visible at once in the dock. |
| `dragThreshold` | `integer` | `20` | Drag distance in pixels required to reveal or hide the dock. |
| `pinnedApps` | `array<string>` | `[]` | List of `.desktop` file IDs pinned to the dock. |

---

## 🛠️ Nexus Control Center Integration

You can also adjust all dock settings graphically via **Nexus Settings** $\rightarrow$ **Panels** $\rightarrow$ **Dock**.
