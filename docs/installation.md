# Installation

OP-Caelestia Shell is a [Quickshell](https://quickshell.org) configuration plus a small compiled C++ plugin. It is meant for
**Arch-based systems (Arch, CachyOS, EndeavourOS) running Hyprland**.

> **Status: beta.** It is developed and tested on one laptop (Arch, Hyprland 0.56, Intel graphics). Packaging for the AUR is planned
> but does not exist yet. Until then, use the installer below.

## What you need

| Needed for | Packages |
| --- | --- |
| The shell itself | `quickshell-git` (AUR; the development build, not an old tagged release), Hyprland |
| Building the plugin | `cmake`, `ninja`, `gcc`, `qt6-base`, `qt6-declarative`, `qt6-imageformats`, `qt6-shadertools` |
| Audio, media, system info | `pipewire`, `libpipewire`, `cava`, `aubio`, `libqalculate`, `lm_sensors`, `power-profiles-daemon` |
| Network, Bluetooth, displays | `networkmanager`, `bluez`, `python-dbus`, `python-gobject`, `brightnessctl`, `ddcutil` |
| Wallpapers, colour schemes, screen recording | `caelestia-cli` (AUR). The shell calls it for `caelestia wallpaper`, `caelestia scheme` and `caelestia record` |
| Screenshots and clipboard | `swappy`, `wl-clipboard`, `slurp`, `grim` |
| Fonts | `ttf-material-symbols-variable`, `ttf-rubik-vf`, `ttf-cascadia-code-nerd` |
| Optional | `hyprmoncfg` (saved display layouts in Nexus > Display), `fprintd` (fingerprint), `howdy` (face unlock) |

## Hyprland version

The Display, Look & feel (Density, Glass, Motion) features change Hyprland **live** through its Lua configuration API, which needs
**Hyprland 0.55 or newer using a `hyprland.lua` config**. On the older `hyprland.conf` format the shell still runs, but those
features do nothing. Hyprland has deprecated the old format and plans to drop it, so this is where things are heading.

## Install with the script

```bash
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/op-caelestia
cd ~/.config/quickshell/op-caelestia
./install.sh
```

The script installs missing packages (asking first), builds the plugin into `.local-caelestia-plugin/` inside the folder, and puts
an `op-caelestia` command in `~/.local/bin`. It runs side by side with vanilla Caelestia: nothing of the upstream install is touched.

## Install by hand

```bash
# 1. Packages (see the table above)
sudo pacman -S --needed cmake ninja gcc qt6-base qt6-declarative qt6-imageformats qt6-shadertools \
    pipewire libpipewire cava aubio libqalculate lm_sensors power-profiles-daemon networkmanager bluez \
    python-dbus python-gobject brightnessctl ddcutil swappy wl-clipboard slurp grim
paru -S --needed quickshell-git caelestia-cli ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd

# 2. Get the shell
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/op-caelestia
cd ~/.config/quickshell/op-caelestia

# 3. Build the plugin into the folder (no root needed)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
DESTDIR="$PWD/.local-caelestia-plugin" cmake --install build

# 4. Start it
./scripts/startup-shell.sh
```

## Start it with Hyprland

Add to your Hyprland config, using the path you cloned to:

```lua
-- hyprland.lua
hl.exec_cmd("~/.config/quickshell/op-caelestia/scripts/startup-shell.sh")
```

```ini
# hyprland.conf (old format)
exec-once = ~/.config/quickshell/op-caelestia/scripts/startup-shell.sh
```

Then add keybinds from [keybindings.md](keybindings.md); without them there is no key to open the launcher or Nexus.

## Managing the shell

```bash
./scripts/startup-shell.sh        # start
./scripts/startup-shell.sh -r     # restart
./scripts/startup-shell.sh -k     # stop
quickshell log                    # live log (add -p <path to shell.qml> if several run)
```

## Troubleshooting

- **Squares instead of icons in file pickers:** the shell sets `QS_ICON_THEME` from your qt6ct (or GTK) icon theme when it starts. If it is still wrong, set `QS_ICON_THEME=<theme name>` yourself.
- **A font you added shows as another font:** Qt reads the installed fonts once at startup. Restart the shell (Nexus > Look & feel offers a button).
- **Something looks broken:** open Nexus > Doctor. It checks services, helpers, portals, crashes and more.
- **Crash:** reports are saved in `~/.cache/quickshell/crashes/`; attach `report.txt` and `log.qslog.log` to an issue.
