# 🛠️ Installation & Setup Manual

This guide covers everything you need to install, build, configure, and run **OP-Caelestia Shell**.

---

## ⚡ 1. Automated Quick Installation (Recommended)

The easiest and fastest way to install OP-Caelestia Shell is with the built-in interactive setup script. It automatically detects your AUR helper (`paru` or `yay`), resolves missing dependencies, compiles the native C++ plugin, creates your default configuration, and configures the global `op-caelestia` command.

> [!TIP]
> **Side-by-side Coexistence with Existing Caelestia**:
> If you already have vanilla Caelestia installed at `~/.config/quickshell/caelestia`, the installer will automatically detect it and install OP-Caelestia side-by-side in `~/.config/quickshell/op-caelestia` without overwriting or deleting any of your existing files!

### Option A: One-Line Remote Installer
```bash
bash <(curl -sSL https://raw.githubusercontent.com/OVERxPOWERED/op-caelestia-shell/main/install.sh)
```

### Option B: Clone & Run Local Installer
```bash
# 1. Clone into your quickshell config folder (op-caelestia or custom)
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/op-caelestia

# 2. Run the installer
cd ~/.config/quickshell/op-caelestia
./install.sh
```

---

## 📋 2. Manual Step-by-Step Installation (For Developers)

If you prefer to install dependencies and build the plugin manually without using the installer script, follow the steps below:

### Step 1: Install Dependencies

```bash
# System Libraries, Build Tools & Audio/Media Services
sudo pacman -S --needed cmake ninja gcc qt6-base qt6-declarative qt6-imageformats qt6-shadertools \
    pipewire libpipewire cava aubio networkmanager lm_sensors brightnessctl ddcutil \
    swappy fish bash python python-dbus libqalculate power-profiles-daemon

# Quickshell Engine, CLI & Fonts (via AUR)
paru -S --needed quickshell-git caelestia-cli ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
```

> [!IMPORTANT]
> `quickshell-git` is required (the latest development git build, not an outdated tagged release).

---

### Step 2: Clone the Repository

```bash
mkdir -p ~/.config/quickshell
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/caelestia
cd ~/.config/quickshell/caelestia
```

---

### Step 3: Build & Install the C++ Plugin

#### Local Build (Recommended / No Root Required)
Builds the native C++ Caelestia plugin and QML components inside a local folder within the repository:

```bash
cd ~/.config/quickshell/caelestia
mkdir -p build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ ..
cmake --build .
DESTDIR="$PWD/../.local-caelestia-plugin" cmake --install .
```

#### System-Wide Installation (Optional)
```bash
cd ~/.config/quickshell/caelestia
mkdir -p build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ ..
cmake --build .
sudo cmake --install .
```

---

## ▶️ 3. Starting the Shell

To start the shell manually in the background:

```bash
# Using the local startup helper:
~/.config/quickshell/caelestia/scripts/startup-shell.sh

# Or via Caelestia CLI (if system-wide installed):
caelestia shell -d
```

---

## ⚡ 4. Setting Up Hyprland Autostart

To automatically launch the shell when you log in to Hyprland:

### If using standard `hyprland.conf`:
Add this line to `~/.config/hypr/hyprland.conf`:

```ini
# Autostart OP-Caelestia Shell on login
exec-once = ~/.config/quickshell/caelestia/scripts/startup-shell.sh
```

### If using Caelestia Dotfiles (`hypr/hyprland/execs.lua`):
Add or update the startup line in `~/.config/hypr/hyprland/execs.lua`:

```lua
hl.exec_cmd("sleep 0.5 && ~/.config/quickshell/caelestia/scripts/startup-shell.sh")
```

---

## ⌨️ 5. Hyprland Keybindings

Add these keybindings to your `~/.config/hypr/hyprland.conf` (or `hypr/hyprland/keybinds.lua`) to trigger shell features:

```ini
# --- OP-Caelestia Shell Keybinds ---

# 3D Taskview / Workspace Overview
bind = SUPER, Tab, global, quickshell:overviewToggle

# Application Launcher & Search
bind = SUPER, Space, global, quickshell:launcherToggle

# Dashboard Overlay
bind = SUPER, D, global, quickshell:dashboardToggle

# Sidebar / Notifications
bind = SUPER, N, global, quickshell:sidebarToggle

# Nexus Settings Control Center
bind = SUPER, I, global, quickshell:nexusToggle

# Lock Screen
bind = SUPER, L, global, quickshell:lockscreenLock
```

---

## 🔍 6. Verification & Troubleshooting

### Check if Quickshell is running:
```bash
pgrep -a quickshell
```
You should see `quickshell -p .../shell.qml` in the output.

### View live logs:
```bash
quickshell log
# Or via CLI
caelestia shell -l
```

### Restart the shell:
```bash
killall -9 quickshell || true
~/.config/quickshell/caelestia/scripts/startup-shell.sh
```
