<h1 align="center">OP-Caelestia Shell</h1>

<p align="center">
  <strong>A desktop shell for Hyprland, built on Quickshell. A fork of Caelestia with a settings app, display management and a health checker.</strong>
</p>

<div align="center">

[![GitHub last commit](https://img.shields.io/github/last-commit/OVERxPOWERED/op-caelestia-shell?style=for-the-badge&labelColor=0f141c&color=80caff)](https://github.com/OVERxPOWERED/op-caelestia-shell/commits/main)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge&labelColor=0f141c&color=38bdf8)](LICENSE)
[![Framework: Quickshell](https://img.shields.io/badge/Framework-Quickshell-ff79c6?style=for-the-badge&labelColor=0f141c&color=f472b6)](https://quickshell.org)
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland-00c853?style=for-the-badge&labelColor=0f141c&color=4ade80)](https://hyprland.org)

</div>

---

## What this is

OP-Caelestia Shell is a fork of [caelestia-dots/shell](https://github.com/caelestia-dots/shell). It keeps Caelestia's look (fluid
shapes, Material You colours) and adds things I wanted for daily use on a laptop: a full settings app, proper display handling,
a place to see what is broken, and more.

> **Status: beta.** It is developed and tested on one machine (Arch, Hyprland 0.56, Intel graphics, one laptop panel plus an
> occasional external display). It works there; expect rough edges elsewhere, and please report them.

## What it adds

- **Nexus**, a settings app with search for every individual setting. [Details](docs/nexus.md)
- **Display management**: plug-in chooser (extend, mirror, display only), saved layouts, mirroring that matches the laptop's shape, per-display interface size, confirm-or-revert for risky changes.
- **Doctor**: health checks for Wi-Fi, Bluetooth, audio, portals, helpers, crashes and more, safe one-click fixes, and an optional background watchdog.
- **Look & feel**: window spacing presets, overview blur, window opacity, animation speed, and app fonts, including your own font files. Everything is off until you turn it on.
- **Workspace overview** with a carousel and a grid, drag to reorder workspaces and move windows.
- **Dock**, **quick notes**, **per-app audio**, a **pattern lock** option, Google Calendar sync, and eight character themes. [Details](docs/features.md)

## Requirements

- An **Arch-based** system (Arch, CachyOS, EndeavourOS) with **Hyprland**. Other distributions and compositors are not supported.
- **Hyprland 0.55 or newer with a `hyprland.lua` config** for the Display and Look & feel features. On the older `hyprland.conf` the shell
  runs, but those features do nothing.
- `quickshell` (0.3 or newer) and `caelestia-cli` (AUR), plus the packages listed in [docs/installation.md](docs/installation.md).

## Install

```bash
git clone https://github.com/OVERxPOWERED/op-caelestia-shell.git ~/.config/quickshell/op-caelestia
cd ~/.config/quickshell/op-caelestia
./install.sh
```

The installer asks before installing packages, builds the plugin (a couple of minutes), and adds an `op-caelestia` command. It runs
next to vanilla Caelestia without touching it. Full instructions, the manual route and troubleshooting are in
[docs/installation.md](docs/installation.md). An AUR package is planned.

After installing, bind keys to the shell's shortcuts; see [docs/keybindings.md](docs/keybindings.md). Without them there is no key
that opens the launcher or Nexus.

## Documentation

| | |
| --- | --- |
| [Installation](docs/installation.md) | Packages, building, autostart, troubleshooting |
| [Keybindings](docs/keybindings.md) | Every shortcut the shell offers, and the command line |
| [Nexus](docs/nexus.md) | The settings app, page by page |
| [Features](docs/features.md) | Dock, overview, notes, lock screen, themes and more |
| [Configuration](docs/configuration.md) | Every `shell.json` option with its default (generated from the source) |

## Contributing

Issues and pull requests are welcome; see [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md). If a problem also happens in vanilla
Caelestia, report it to [caelestia-dots/shell](https://github.com/caelestia-dots/shell).

## Credits

- [caelestia-dots/shell](https://github.com/caelestia-dots/shell): the shell this is forked from, and the CLI it depends on.
- [Quickshell](https://quickshell.org) by outfoxxed: the toolkit it is built on.
- [Hyprland](https://hyprland.org): the compositor.
- [hyprmoncfg](https://github.com/crmne/hyprmoncfg): the display-profile engine behind saved layouts.

## License

[GNU General Public License v3.0](LICENSE), the same as upstream.
