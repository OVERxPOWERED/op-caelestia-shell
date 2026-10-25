# Keybindings

The shell registers **global shortcuts** with Hyprland under the app id `caelestia`. They do nothing until you bind a key to them.
Bind them in your Hyprland config:

```lua
-- hyprland.lua
hl.bind("SUPER + Space", hl.dsp.global("caelestia:launcher"), { release = true })
hl.bind("SUPER + Tab",   hl.dsp.global("caelestia:overview"))
hl.bind("SUPER + I",     hl.dsp.global("caelestia:nexus"))
```

```ini
# hyprland.conf (old format)
bindr = SUPER, Space, global, caelestia:launcher
bind  = SUPER, Tab,   global, caelestia:overview
bind  = SUPER, I,     global, caelestia:nexus
```

The key choices above are only examples; use whatever suits you.

## Shortcuts

| Name | What it does |
| --- | --- |
| `caelestia:launcher` | Open or close the app launcher |
| `caelestia:launcherInterrupt` | Interrupt the launcher keybind (for a launcher bound to a lone modifier key, so combos like Super+key do not open it) |
| `caelestia:overview` | Open or close the workspace overview |
| `caelestia:showall` | Toggle launcher, dashboard and OSD together |
| `caelestia:nexus` | Open or close Nexus, the settings app |
| `caelestia:dashboard` | Toggle the dashboard |
| `caelestia:sidebar` | Toggle the sidebar (notifications) |
| `caelestia:utilities` | Toggle utilities (quick toggles) |
| `caelestia:session` | Toggle the session (power) menu |
| `caelestia:lock` | Lock the screen |
| `caelestia:clearNotifs` | Dismiss all notifications |
| `caelestia:brightnessUp`, `caelestia:brightnessDown` | Screen brightness |
| `caelestia:mediaToggle`, `caelestia:mediaNext`, `caelestia:mediaPrev`, `caelestia:mediaStop` | Media keys |
| `caelestia:screenshot`, `caelestia:screenshotFreeze`, `caelestia:screenshotClip`, `caelestia:screenshotFreezeClip` | Open the screenshot tool (also in freeze mode, and to the clipboard) |
| `caelestia:refreshDevices` | Reload devices |

## Command line

Everything the shell exposes can also be called from a terminal through Quickshell's IPC, for example:

```bash
qs -p ~/.config/quickshell/op-caelestia/shell.qml ipc show           # list all targets and functions
qs -p ~/.config/quickshell/op-caelestia/shell.qml ipc call nexus open
```
