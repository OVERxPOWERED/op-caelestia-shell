# ⚙️ Nexus Settings Control Center

**Nexus** is the unified graphical settings panel for Caelestia Shell. It provides a complete control center to customize all visual, functional, and system options without having to manually edit JSON files.

---

## 🧭 Page & Subpage Navigation Map

```
Nexus Settings
├── 🎨 Appearance
│   └── Wallpaper & style
│       ├── Wallpapers (WallpaperSelect.qml)
│       ├── Categories (WallpaperCategory.qml)
│       ├── Colours & Palette (ColourSelect.qml)
│       ├── Themes Gallery (ThemeSelect.qml) [NEW]
│       └── Desktop & Background (DesktopBackground.qml) [NEW]
│
├── 🌐 Connectivity
│   ├── Network (Wi-Fi, Ethernet, VPN, Saved Networks)
│   ├── Connected devices (Bluetooth Pairing & Device Info)
│   └── Audio (Master devices & App volume levels)
│
├── ⚡ System
│   ├── Updates (System Package Updates)
│   ├── Plugins (Manage Caelestia Plugins)
│   └── Power & idle (PowerIdlePage.qml) [NEW]
│
├── 🖥️ Shell
│   ├── Panels
│   │   ├── Dashboard (DashboardPanel.qml)
│   │   ├── Taskbar & Components (TaskbarPanel.qml)
│   │   ├── Launcher (LauncherPanel.qml)
│   │   ├── Sidebar (SidebarPanel.qml)
│   │   ├── Utilities (UtilitiesPanel.qml)
│   │   ├── Dock (DockPanel.qml) [NEW]
│   │   ├── OSD Overlays (OsdPanel.qml) [NEW]
│   │   └── Overview / Taskview (OverviewPanel.qml) [NEW]
│   ├── Apps (Default apps, Favorites, Hidden apps)
│   ├── Lock screen (LockScreenPage.qml) [NEW]
│   ├── Services (Poll intervals, Lyrics backend)
│   └── Language & region (Locale, Weather location, Units)
│
└── ℹ️ About
    └── About Caelestia (System info, versions, and credits)
```

---

## 🌟 Detailed Overview of New Subpages

### 1. Dock Settings (`Panels` $\rightarrow$ `Dock`)
- Toggle dock visibility and bottom screen edge hover auto-hide.
- Adjust maximum visible slots (1 to 20 apps) and drag sensitivity threshold.
- Interactive pinned applications manager (unpin with 1 click or add new pinned apps).

### 2. OSD Overlays (`Panels` $\rightarrow$ `OSD`)
- Master on-screen display switch.
- Brightness and Microphone mute overlay toggles.
- Auto-hide delay timeout slider (from 500ms to 5000ms).

### 3. Taskview Overview (`Panels` $\rightarrow$ `Overview`)
- Choose default opening tab (Workspace Carousel, All Windows Grid, or Scratchpads).
- Shortcut reference guide.

### 4. Theme Gallery (`Wallpaper & style` $\rightarrow$ `Themes`)
- Visual card grid previewing all themes in `assets/themes/`.
- 1-click apply to switch wallpapers, animations, and color schemes.
- Custom wallpaper folder path configuration.

### 5. Desktop Background (`Wallpaper & style` $\rightarrow$ `Desktop & background`)
- Desktop clock widget on/off toggle.
- Background audio visualizer settings (auto-hide on silence, blur, bar spacing, bar rounding).
- Window border thickness and corner rounding radius sliders.

### 6. Lock Screen & Security (`Shell` $\rightarrow$ `Lock screen`)
- 3x3 pattern unlock toggle and interactive pattern recorder modal.
- Fingerprint (`fprintd`) attempt limits.
- Howdy infrared face unlock attempt limits and wake scan triggers.
- Lock screen wallpaper blur toggle and logo recoloring.

### 7. Power & Idle (`System` $\rightarrow$ `Power & idle`)
- Critical battery auto-hibernate percentage threshold stepper.
- Sleep inhibitors (keep awake during audio playback, keep awake when plugged into AC power).
- Inactivity timeouts for screen lock, display off (DPMS), and system suspend.
- Lock before sleep toggle.
