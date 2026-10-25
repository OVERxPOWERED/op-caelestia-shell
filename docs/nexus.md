# Nexus, the settings app

Nexus is the shell's settings window. Open it with the `caelestia:nexus` shortcut (see [keybindings.md](keybindings.md)) or
`qs -p <shell.qml> ipc call nexus open`. Use the search box at the top to find any individual setting; it understands
synonyms (typing "wifi" finds Network).

Changes are saved to `~/.config/caelestia/shell.json` (see [configuration.md](configuration.md)). Your Hyprland config files are
never rewritten: where Nexus changes Hyprland (gaps, opacity, animations, display layout), it applies the change live and
re-applies it after every Hyprland config reload, and keeps its own choices in `~/.local/state/caelestia/`.

## Pages

| Page | What is in it |
| --- | --- |
| **Wallpaper & style** | Wallpapers, colour schemes, character themes, desktop clock and visualiser, window borders |
| **Look & feel** | Density (interface size, window gaps and border), Glass (overview blur, window opacity, solid text windows), Motion (animation speed, windows that move like the shell), App fonts (including your own font files) |
| **Display** | Layout and arrangement, resolution, refresh rate, scale, rotation, mirroring, per-display interface size, saved layouts |
| **Network** | Wi-Fi, Ethernet (IPv4/IPv6), VPN, saved networks |
| **Connected devices** | Bluetooth pairing and devices |
| **Audio** | Output and input devices, per-app volume and routing, combined output |
| **Updates** | System updates |
| **Plugins** | Plugin management (not wired up yet) |
| **Power & idle** | Battery alerts, sleep and lock timeouts, idle inhibitors |
| **Doctor** | Health checks (services, radios, helpers, portals, audio, monitors, crashes, plugin build, disk), one-click fixes where they are safe, and an optional background watchdog |
| **Panels** | Dashboard, taskbar, launcher, sidebar, utilities, dock, on-screen display, overview, scratchpad and notes |
| **Apps** | Default apps, favourites, hidden apps |
| **Lock screen** | Pattern unlock, fingerprint and face unlock, lock screen look |
| **Services** | Poll intervals, lyrics backend, Google Calendar |
| **Language & region** | Interface language, weather location, units |
| **About** | Versions and credits |

## Display

Nexus > Display is a front end for [hyprmoncfg](https://github.com/crmne/hyprmoncfg) (optional but recommended: it provides saved
layouts). Plugging in a display opens a chooser (Extend, Mirror, Display only, Laptop only). Every change that could leave you
without a picture is confirmed with a 15 second Keep / Revert countdown, and unplugging the last real display is handled so the
laptop panel comes back.

## Doctor

Doctor runs read-only checks and offers a fix only where one is safe: switching radios on, stopping duplicate Bluetooth helpers,
restarting portals or audio, starting the polkit agent, and removing duplicate saved Wi-Fi profiles one by one (each with a
confirmation). The optional watchdog repeats the quick checks every 2, 5, 15 or 30 minutes at the lowest priority (about a tenth of
a second of CPU) and shows one notification per new problem. It pauses in game mode and can be turned off on the same page.
