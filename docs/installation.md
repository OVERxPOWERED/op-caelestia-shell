# 🛠️ Installation & Setup Manual

This guide covers everything you need to install, build, configure, and autostart **op-caelestia-shell**.

---

## 📋 1. Prerequisites & Dependencies

### Arch Linux / CachyOS Dependencies

Install the required system libraries and utilities via `pacman` and `paru` / `yay`:

```sh
# System & Build Tools
sudo pacman -S --needed cmake ninja gcc qt6-base qt6-declarative qt6-imageformats qt6-shadertools \
    pipewire libpipewire cava aubio networkmanager lm_sensors brightnessctl ddcutil \
    swappy fish bash python python-dbus libqalculate power-profiles-daemon

# Fonts & Icons (AUR)
paru -S --needed quickshell-git caelestia-cli ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
```

> [!IMPORTANT]
> `quickshell-git` is required (the git version, not an outdated release build).

---

## 🚀 2. Building & Running the Shell

You have two installation methods available:

### Option A: Local Build & Run (Recommended / No Root Required)

This builds the C++ plugin and QML components inside a local folder within the repository.

1. **Clone the repository:**
   ```sh
   mkdir -p ~/.config/quickshell
   git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/caelestia
   cd ~/.config/quickshell/caelestia
   ```

2. **Build and install the local plugin:**
   ```sh
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
   cmake --build build
   DESTDIR="$PWD/.local-caelestia-plugin" cmake --install build
   ```

3. **Launch the shell:**
   ```sh
   ./scripts/startup-shell.sh -d -n
   ```

---

### Option B: System-Wide Installation (Standard Caelestia Integration)

This installs the C++ plugin and shell into standard system directories (`/usr/lib/qt6/qml` and `/etc/xdg/quickshell/caelestia`).

1. **Clone and build with root install prefix:**
   ```sh
   cd ~/.config/quickshell/caelestia
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
   cmake --build build
   sudo cmake --install build
   ```

2. **Launch the shell:**
   ```sh
   caelestia shell -d
   # Or using quickshell CLI:
   qs -c caelestia -n -d
   ```

---

## ⚡ 3. Setting Up Hyprland Autostart

To have the shell start automatically on login:

### If using standard `hyprland.conf`:
Add this line to `~/.config/hypr/hyprland.conf`:

```ini
# Autostart Caelestia Shell
exec-once = ~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n
```

### If using Caelestia Dotfiles (`hypr/hyprland/execs.lua`):
Add or update the startup line in `~/.config/hypr/hyprland/execs.lua`:

```lua
hl.exec_cmd("sleep 0.5 && ~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n")
```

---

## ⌨️ 4. Hyprland Keybindings Setup

Add these keybindings to your `~/.config/hypr/hyprland.conf` (or `hypr/hyprland/keybinds.lua`) to trigger the shell features:

```ini
# --- OP Caelestia Shell Keybinds ---

# Taskview / 3D Workspace Overview
bind = SUPER, Tab, global, quickshell:overviewToggle

# Application Launcher
bind = SUPER, Space, global, quickshell:launcherToggle

# Dashboard Overlay
bind = SUPER, D, global, quickshell:dashboardToggle

# Notifications & Sidebar
bind = SUPER, N, global, quickshell:sidebarToggle

# Nexus Settings Control Center
bind = SUPER, I, exec, caelestia shell nexus open

# Lock Screen
bind = SUPER, L, exec, loginctl lock-session
```

---

## 🔍 5. Verification & Troubleshooting

### How to verify the shell is running:
```sh
pgrep -a quickshell
```
You should see `quickshell -p .../shell.qml` in the process list.

### Viewing live logs:
```sh
quickshell log
# Or check the active log file:
ls -t /run/user/$UID/quickshell/by-id/*/log.qslog | head -n1 | xargs tail -f
```

### Restarting the shell manually:
```sh
killall -9 quickshell || true
~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n
```
