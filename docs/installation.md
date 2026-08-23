# 🛠️ Installation & Setup Manual

This guide covers everything you need to clone, build, configure, and run **op-caelestia-shell**.

---

## 📋 1. Prerequisites & Dependencies

### Arch Linux / CachyOS Dependencies

Install the required system packages and tools:

```sh
# System Libraries, Build Tools & Audio/Media Services
sudo pacman -S --needed cmake ninja gcc qt6-base qt6-declarative qt6-imageformats qt6-shadertools \
    pipewire libpipewire cava aubio networkmanager lm_sensors brightnessctl ddcutil \
    swappy fish bash python python-dbus libqalculate power-profiles-daemon

# Quickshell Engine, CLI & Fonts (via AUR)
paru -S --needed quickshell-git caelestia-cli ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
```

> [!IMPORTANT]
> `quickshell-git` is required (the latest development git build, not an outdated tagged version).

---

## 📥 2. Clone the Repository

Clone this repository into your Quickshell configuration folder:

```sh
mkdir -p ~/.config/quickshell
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/caelestia
cd ~/.config/quickshell/caelestia
```

---

## 🔨 3. Build & Install the Plugin

Choose either **Local Build** (recommended, no root needed) or **System-Wide Install**:

### Option A: Local Build (Recommended / No Root Required)
Builds the native C++ Caelestia plugin and QML components inside a local folder within the repository:

```sh
cd ~/.config/quickshell/caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
DESTDIR="$PWD/.local-caelestia-plugin" cmake --install build
```

### Option B: System-Wide Installation
Installs the C++ plugin and shell into standard system directories (`/usr/lib/qt6/qml` and `/etc/xdg/quickshell/caelestia`):

```sh
cd ~/.config/quickshell/caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

---

## ▶️ 4. Starting the Shell

To start the shell manually in the background:

```sh
# If you used Option A (Local Build):
~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n

# If you used Option B (System-Wide Install):
caelestia shell -d
```

---

## ⚡ 5. Setting Up Hyprland Autostart

To automatically launch the shell when you log in to Hyprland:

### If using standard `hyprland.conf`:
Add this line to `~/.config/hypr/hyprland.conf`:

```ini
# Autostart OP Caelestia Shell on login
exec-once = ~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n
```

### If using Caelestia Dotfiles (`hypr/hyprland/execs.lua`):
Add or update the startup line in `~/.config/hypr/hyprland/execs.lua`:

```lua
hl.exec_cmd("sleep 0.5 && ~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n")
```

---

## ⌨️ 6. Hyprland Keybindings

Add these keybindings to your `~/.config/hypr/hyprland.conf` (or `hypr/hyprland/keybinds.lua`) to trigger the shell features:

```ini
# --- OP Caelestia Shell Keybinds ---

# 3D Taskview / Workspace Overview
bind = SUPER, Tab, global, quickshell:overviewToggle

# Application Launcher & Search
bind = SUPER, Space, global, quickshell:launcherToggle

# Dashboard Overlay
bind = SUPER, D, global, quickshell:dashboardToggle

# Sidebar / Notifications
bind = SUPER, N, global, quickshell:sidebarToggle

# Nexus Settings Control Center
bind = SUPER, I, exec, caelestia shell nexus open

# Lock Screen
bind = SUPER, L, exec, loginctl lock-session
```

---

## 🔍 7. Verification & Troubleshooting

### Check if Quickshell is running:
```sh
pgrep -a quickshell
```
You should see `quickshell -p .../shell.qml` in the output.

### View live logs:
```sh
quickshell log
```

### Restart the shell:
```sh
killall -9 quickshell || true
~/.config/quickshell/caelestia/scripts/startup-shell.sh -d -n
```
