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

Themes are stored under `~/.config/quickshell/caelestia/assets/themes/` (or custom configured wallpaper directory):

```
assets/themes/
├── Cyberpunk/
│   ├── wall.png            # Main wallpaper (1920x1080 or 4K)
│   ├── colors.json         # Material 3 tonal palette definitions
│   └── visuals/            # Optional theme-specific GIFs / illustrations
│       ├── media.gif
│       └── session.gif
└── Nord-Aurora/
    ├── wall.jpg
    └── colors.json
```

---

## 🚀 How to Create a Custom Theme

1. Create a new directory inside `assets/themes/<YourThemeName>/`.
2. Add your primary wallpaper as `wall.png` or `wall.jpg`.
3. (Optional) Provide a custom `colors.json` containing Material 3 tone definitions (or let Matugen generate them automatically).
4. (Optional) Place custom animations into `visuals/`.
5. Open **Nexus Settings** $\rightarrow$ **Wallpaper & style** $\rightarrow$ **Themes** to activate your new theme!

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
