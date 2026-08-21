# 🪟 Taskview & Workspace Overview

The **Taskview Overview** provides a visual, multi-workspace management overlay for Hyprland with live window previews, window moving, and search capabilities.

---

## ✨ Features

- **3D Workspace Carousel**: Interactive fluid carousel displaying all active Hyprland workspaces with miniature live client window representations.
- **All Windows Grid**: Complete grid view across all workspaces with fast search to locate any window instantly.
- **Special / Scratchpad Carousel**: Dedicated carousel for inspecting and managing scratchpad dropdowns.
- **Window Management Direct Actions**:
  - **Click** any window to focus and raise it.
  - **Drag & Drop** windows between workspace cards to move them across workspaces.
  - **Middle-click** any window tile to close it immediately.

---

## ⌨️ Shortcuts & Hotkeys

To trigger the Overview overlay, configure a Hyprland keybinding in your `hyprland.conf`:

```ini
# Toggle Overview Taskview
bind = SUPER, Tab, global, quickshell:overviewToggle
```

### Navigation Keys within Overview:
- **Left / Right Arrows** or **Mouse Wheel**: Cycle through workspaces in the carousel.
- **Tab / Shift+Tab**: Switch between Carousel, All Windows Grid, and Scratchpads.
- **Escape**: Close Overview and return to active workspace.

---

## ⚙️ Configuration (`shell.json`)

To configure default Overview behavior, add the following to `~/.config/caelestia/shell.json`:

```json
{
  "overview": {
    "defaultTab": "carousel",
    "showSpecialWorkspaces": true,
    "scale": 1.0
  }
}
```

---

## 🛠️ Nexus Control Center Integration

You can set the default opening tab and learn more about Overview shortcuts inside **Nexus Settings** $\rightarrow$ **Panels** $\rightarrow$ **Overview**.
