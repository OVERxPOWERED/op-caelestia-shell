<h1 align="center">🌌 OP-Caelestia Shell</h1>

<p align="center">
  <strong>An enhanced, fluid, and feature-packed desktop shell for Hyprland built on Quickshell and Qt6/QML.</strong>
</p>

<div align="center">

[![GitHub last commit](https://img.shields.io/github/last-commit/OVERxPOWERED/op-caelestia-shell?style=for-the-badge&labelColor=0f141c&color=80caff)](https://github.com/OVERxPOWERED/op-caelestia-shell/commits/custom)
[![GitHub stars](https://img.shields.io/github/stars/OVERxPOWERED/op-caelestia-shell?style=for-the-badge&labelColor=0f141c&color=94a3b8)](https://github.com/OVERxPOWERED/op-caelestia-shell/stargazers)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge&labelColor=0f141c&color=38bdf8)](LICENSE)
[![Framework: Quickshell](https://img.shields.io/badge/Framework-Quickshell-ff79c6?style=for-the-badge&labelColor=0f141c&color=f472b6)](https://quickshell.outfoxxed.me)
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland-00c853?style=for-the-badge&labelColor=0f141c&color=4ade80)](https://hyprland.org)

</div>

---

## ✨ Overview

**OP-Caelestia Shell** is a heavily customized, feature-rich fork of the Caelestia desktop shell. It preserves the fluid morphing aesthetic and Material You dynamic color generation of the original project while introducing powerful desktop workflow additions: an interactive application dock, a 3D taskview workspace overview, live animated wallpaper playback, pattern gesture security, per-app audio stream mixing, and automated hardware GPU autodetection.

---

## 🌟 Enhanced Feature Highlights

| Feature | Description | Deep Dive Guide |
| :--- | :--- | :--- |
| 🪟 **Taskview / Workspace Overview** | Fluid 3D workspace carousel, full-screen search grid across all workspaces, scratchpad manager, and drag-and-drop window moving. | [📖 Overview Guide](docs/overview.md) |
| 🖼️ **Live & Animated Wallpapers** | Native GIF and animated wallpaper playback with silky smooth opacity fade transitions and minimal CPU overhead. | [📖 Changes & Details](changes.md) |
| 🚢 **Application Dock** | Floating macOS-style dock with pinned launchers, running window indicators, active window badges, context menus, and autohide. | [📖 Dock Guide](docs/dock.md) |
| 🔒 **Pattern Gesture Lock Screen** | Android-style 3x3 gesture pattern unlock, visual pattern recorder in Nexus settings, and power confirmation dialogs. | [📖 Lockscreen Guide](docs/lockscreen.md) |
| 🔊 **Per-App Audio Control** | Live individual application volume sliders, mute toggles, and dynamic Pipewire audio stream routing. | [📖 Audio Guide](docs/audio.md) |
| 🎨 **Theme Engine & Dynamic Palettes** | Multi-asset theme bundles, launcher `:theme` command, Nexus gallery view, and automatic Material You color extraction. | [📖 Themes Guide](docs/themes.md) |
| ⚙️ **Expanded Nexus Control Center** | Dedicated graphical settings subpages for Dock, OSD, Overview, Themes, Power, and System Hardware. | [📖 Nexus Guide](docs/nexus.md) |
| 💻 **Universal Hardware Engine** | Automatic GPU driver detection (Intel Xe/i915, AMD, NVIDIA, headless) and dynamic C++ plugin path resolution. | [📖 Hardware Guide](docs/hardware-compatibility.md) |

---

## 🚀 Quick Start & Installation

### ⚡ Option 1: Automated Installer (Recommended)

The interactive setup script handles dependency checks via `paru`/`yay`, builds the isolated native C++ plugin, and configures the `op-caelestia` command.

> [!TIP]
> **Side-by-side Coexistence**: If you already have vanilla Caelestia installed at `~/.config/quickshell/caelestia`, the installer will automatically set up OP-Caelestia in `~/.config/quickshell/op-caelestia` without overwriting or conflicting with your existing setup!

```bash
# One-Line Remote Installer
bash <(curl -sSL https://raw.githubusercontent.com/OVERxPOWERED/op-caelestia-shell/main/install.sh)
```

Or clone and run locally:

```bash
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/op-caelestia
cd ~/.config/quickshell/op-caelestia && ./install.sh
```

Once installed, you can control the shell anytime from your terminal:
* **Start**: `op-caelestia`
* **Restart**: `op-caelestia -r`
* **Stop**: `op-caelestia -k`

---

### 📦 Option 2: Manual Step-by-Step Build

<details>
<summary><b>Click to expand manual setup instructions</b></summary>

```bash
# 1. Install dependencies via AUR helper (paru or yay)
paru -S quickshell-git caelestia-cli \
        qt6-base qt6-declarative qt6-imageformats qt6-shadertools \
        libpipewire libcava aubio ddcutil brightnessctl networkmanager \
        power-profiles-daemon swappy lm_sensors libqalculate fish bash \
        ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd \
        cmake ninja gcc-libs glibc

# 2. Clone the repository
mkdir -p ~/.config/quickshell
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/caelestia
cd ~/.config/quickshell/caelestia

# 3. Build and install the native C++ plugin locally
mkdir -p build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ ..
cmake --build .
DESTDIR="$PWD/../.local-caelestia-plugin" cmake --install .

# 4. Launch the shell
cd .. && ./scripts/startup-shell.sh
```

For complete troubleshooting, system-wide installation, and Nix setup, read the full [Installation Manual](docs/installation.md).

</details>

---

### ❄️ Nix / NixOS

You can run the shell directly using Nix:

```bash
nix run github:OVERxPOWERED/op-caelestia-shell#with-cli
```

Or include it in your NixOS / Home Manager configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    caelestia-shell = {
      url = "github:OVERxPOWERED/op-caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

---

## ⌨️ Hyprland Integration & Keybindings

### 1. Autostarting with Hyprland

Add the startup command to your `~/.config/hypr/hyprland.conf`:

```ini
# Autostart OP-Caelestia Shell
exec-once = ~/.config/quickshell/caelestia/scripts/startup-shell.sh
```

Or if you are using Caelestia dotfiles (`hypr/hyprland/execs.lua`):

```lua
hl.exec_cmd("sleep 0.5 && ~/.config/quickshell/caelestia/scripts/startup-shell.sh")
```

---

### 2. Useful Global Keybindings

Configure global DBus shortcuts in your `hyprland.conf` to control shell components:

```ini
# Taskview / Workspace Overview
bind = SUPER, Tab, global, quickshell:overviewToggle

# Application Launcher
bind = SUPER, SUPER_L, global, quickshell:launcherToggle

# Nexus Control Center
bind = SUPER, N, global, quickshell:nexusToggle

# Lockscreen
bind = SUPER, L, global, quickshell:lockscreenLock

# Wallpaper Picker
bind = SUPER, W, global, quickshell:wallpaperPickerToggle
```

---

## 🛠️ Configuration (`shell.json`)

All shell preferences and custom module settings live in `~/.config/caelestia/shell.json`.

```json
{
  "dock": {
    "enabled": true,
    "position": "bottom",
    "autoHide": false,
    "scale": 1.0,
    "pinnedApps": [
      "firefox.desktop",
      "kitty.desktop",
      "thunar.desktop",
      "spotify.desktop"
    ]
  },
  "overview": {
    "defaultTab": "carousel",
    "showSpecialWorkspaces": true,
    "scale": 1.0
  },
  "lock": {
    "patternEnabled": true,
    "patternConfirmation": true
  },
  "background": {
    "wallpaperEnabled": true
  }
}
```

> [!NOTE]
> For the complete schema, per-monitor configuration overrides, and default values, see the [Configuration Reference Guide](docs/configuration.md).

---

## 📚 Documentation Index

Explore the dedicated documentation guides in [`docs/`](docs/):

* 🛠️ **[Installation & Setup Guide](docs/installation.md)** — Dependencies, C++ plugin building, local resolution, and autostart.
* 🚢 **[Dock Manual](docs/dock.md)** — Pinned applications, indicator behaviors, context menus, and customization.
* 🪟 **[Overview & Taskview Manual](docs/overview.md)** — Workspace carousel, scratchpad manager, and window operations.
* 🎨 **[Theme Engine Manual](docs/themes.md)** — Dynamic palette generation, Material You theming, and preset packages.
* 🔒 **[Lock Screen & Security](docs/lockscreen.md)** — 3x3 Gesture pattern lock, recorder modal, and PAM authentication.
* 🔊 **[Audio Management](docs/audio.md)** — Per-app audio stream mixing and device routing.
* 📶 **[Hotspot & Tethering](docs/hotspot.md)** — Wi-Fi AP broadcasting, client monitoring, and credentials management.
* ⚙️ **[Nexus Control Center](docs/nexus.md)** — Quick settings toggles, network/bluetooth trays, and preferences.
* 💻 **[Hardware Compatibility](docs/hardware-compatibility.md)** — Intel Xe, AMD, NVIDIA GPU engine autodetection.
* 📖 **[Configuration Reference](docs/configuration.md)** — Complete `shell.json` option reference.

---

## 🤝 Credits & Acknowledgements

* **[caelestia-dots/shell](https://github.com/caelestia-dots/shell)** — The original upstream Caelestia shell foundation.
* **[Quickshell](https://quickshell.outfoxxed.me)** — The powerful QML desktop shell engine by Outfoxxed.
* **[Hyprland](https://hyprland.org)** — The dynamic tiling Wayland compositor.

---

<p align="center">
  Licensed under the <a href="LICENSE">GNU General Public License v3.0</a>.
</p>
