# 🎨 Dynamic Multi-Asset Theme Engine

The **Theme Engine** bundles wallpapers, animations, color palettes, and UI accents into modular theme packages that can be switched with one click.

---

## ✨ Features

- **Modular Theme Packages**: Each theme directory bundles desktop wallpapers, UI GIFs, and Material 3 color palettes.
- **Launcher `:theme` Prefix**: Type `:theme` in the application launcher to search, preview, and apply themes on the fly.
- **Nexus Theme Gallery**: Graphical card grid with instant previews in Nexus Settings.
- **Automatic System Theming**: Swapping themes automatically recolors Caelestia Shell, notifications, Hyprland borders, and terminal color schemes.

---

## 📁 Theme Directory Structure

Themes are stored under `assets/themes/` (inside your quickshell shell folder, e.g. `~/.config/quickshell/op-caelestia/assets/themes/`):

```
assets/themes/
├── Cyberpunk/
│   ├── wallpaper.jpg       # Main wallpaper (1920x1080 or 4K)
│   ├── colors.json         # (Optional) Material 3 tonal palette overrides
│   └── visuals/            # (Optional) Theme-specific GIFs / illustrations
│       ├── media.gif
│       └── session.gif
└── Nord-Aurora/
    ├── wallpaper.png
    └── colors.json
```

---

## 🚀 How to Create a Custom Theme

1. Create a new directory inside `assets/themes/<YourThemeName>/`.
2. Add your primary wallpaper as `wallpaper.jpg` or `wallpaper.png`.
3. *(Optional)* Place custom GIF animations inside a `visuals/` subfolder (e.g. `media.gif` or `session.gif`).
4. Open **Nexus Settings** $\rightarrow$ **Wallpaper & style** $\rightarrow$ **Themes** (or type `:theme <name>` in the launcher) to activate your new theme instantly!

---

## ⚙️ Configuration Options (`shell.json`)

```json
{
  "paths": {
    "wallpaperDir": "~/Pictures/Wallpapers"
  },
  "services": {
    "smartScheme": true
  }
}
```
