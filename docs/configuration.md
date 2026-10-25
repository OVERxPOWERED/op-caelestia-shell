# Configuration reference

Settings live in `~/.config/caelestia/shell.json`. You rarely need to edit it by hand: **Nexus** (the settings app) changes
most of them, and the file only contains what you changed. Anything missing falls back to the default shown here.

Per-monitor overrides go in `~/.config/caelestia/monitors/<monitor name>/shell.json`; they use the same keys and only
affect that display (Nexus uses this for Display > Interface size).

> This page is generated from the plugin's source by `scripts/gen-config-docs.py`. Do not edit it by hand.

Dotted names are nested objects: `dock.maxSlots` is `{ "dock": { "maxSlots": 5 } }`.

## `general`

| Option | Type | Default |
| --- | --- | --- |
| `general.logo` | string | empty |
| `general.language` | string | empty |
| `general.showOverFullscreen` | bool | `false` |
| `general.mediaGifSpeedAdjustment` | number | `300` |
| `general.sessionGifSpeed` | number | `0.7` |

## `background`

| Option | Type | Default |
| --- | --- | --- |
| `background.enabled` | bool | `true` |
| `background.wallpaperEnabled` | bool | `true` |
| `background.desktopClock.enabled` | bool | `false` |
| `background.desktopClock.scale` | number | `1.0` |
| `background.desktopClock.invertColors` | bool | `false` |
| `background.desktopClock.position.left` | number | `-1` |
| `background.desktopClock.position.top` | number | `-1` |
| `background.desktopClock.position.right` | number | `2` |
| `background.desktopClock.position.bottom` | number | `2` |
| `background.desktopClock.background.enabled` | bool | `false` |
| `background.desktopClock.background.opacity` | number | `0.7` |
| `background.desktopClock.background.blur` | bool | `true` |
| `background.desktopClock.shadow.enabled` | bool | `true` |
| `background.desktopClock.shadow.opacity` | number | `0.7` |
| `background.desktopClock.shadow.blur` | number | `0.4` |
| `background.visualiser.enabled` | bool | `false` |
| `background.visualiser.autoHide` | bool | `true` |
| `background.visualiser.blur` | bool | `false` |
| `background.visualiser.rounding` | number | `1` |
| `background.visualiser.spacing` | number | `1` |

## `bar`

| Option | Type | Default |
| --- | --- | --- |
| `bar.persistent` | bool | `true` |
| `bar.showOnHover` | bool | `true` |
| `bar.dragThreshold` | int | `20` |
| `bar.excludedScreens` | list of strings | empty |
| `bar.statusIcons` | list | `built-in list` |
| `bar.entries` | list | `built-in list` |
| `bar.scrollActions.workspaces` | bool | `true` |
| `bar.scrollActions.volume` | bool | `true` |
| `bar.scrollActions.brightness` | bool | `true` |
| `bar.popouts.activeWindow` | bool | `true` |
| `bar.popouts.tray` | bool | `true` |
| `bar.popouts.statusIcons` | bool | `true` |
| `bar.workspaces.shown` | int | `5` |
| `bar.workspaces.activeIndicator` | bool | `true` |
| `bar.workspaces.occupiedBg` | bool | `false` |
| `bar.workspaces.showUnoccupied` | bool | `true` |
| `bar.workspaces.perMonitor` | bool | `true` |
| `bar.workspaces.showWindows` | bool | `true` |
| `bar.workspaces.showWindowsOnSpecialWorkspaces` | bool | `true` |
| `bar.workspaces.maxWindowIcons` | int | `5` |
| `bar.workspaces.activeTrail` | bool | `true` |
| `bar.workspaces.label` | string | `" "` |
| `bar.workspaces.occupiedLabel` | string | `"󰮯"` |
| `bar.workspaces.activeLabel` | string | `"󰮯"` |
| `bar.activeWindow.compact` | bool | `false` |
| `bar.activeWindow.inverted` | bool | `false` |
| `bar.activeWindow.showOnHover` | bool | `true` |
| `bar.tray.background` | bool | `false` |
| `bar.tray.recolour` | bool | `false` |
| `bar.tray.compact` | bool | `false` |
| `bar.tray.hiddenIcons` | list of strings | empty |
| `bar.clock.background` | bool | `false` |
| `bar.clock.showDate` | bool | `false` |
| `bar.clock.showIcon` | bool | `true` |
| `bar.clock.showSeconds` | bool | `false` |

## `border`

| Option | Type | Default |
| --- | --- | --- |
| `border.thickness` | int | `10` |
| `border.rounding` | int | `25` |
| `border.smoothing` | int | `20` |

## `dashboard`

| Option | Type | Default |
| --- | --- | --- |
| `dashboard.enabled` | bool | `true` |
| `dashboard.showOnHover` | bool | `true` |
| `dashboard.showDashboard` | bool | `true` |
| `dashboard.showMedia` | bool | `true` |
| `dashboard.showPerformance` | bool | `true` |
| `dashboard.showWeather` | bool | `true` |
| `dashboard.showClockSeconds` | bool | `false` |
| `dashboard.mediaUpdateInterval` | int | `500` |
| `dashboard.resourceUpdateInterval` | int | `1000` |
| `dashboard.dragThreshold` | int | `50` |
| `dashboard.performance.showBattery` | bool | `true` |
| `dashboard.performance.showGpu` | bool | `true` |
| `dashboard.performance.showCpu` | bool | `true` |
| `dashboard.performance.showMemory` | bool | `true` |
| `dashboard.performance.showStorage` | bool | `true` |
| `dashboard.performance.showNetwork` | bool | `true` |
| `dashboard.pomodoro.focusDuration` | int | `25` |
| `dashboard.pomodoro.shortBreakDuration` | int | `5` |
| `dashboard.pomodoro.longBreakDuration` | int | `15` |
| `dashboard.pomodoro.sessionsBeforeLongBreak` | int | `4` |
| `dashboard.pomodoro.defaultToPomodoro` | bool | `true` |

## `dock`

| Option | Type | Default |
| --- | --- | --- |
| `dock.enabled` | bool | `true` |
| `dock.showOnHover` | bool | `true` |
| `dock.scrollToLauncher` | bool | `false` |
| `dock.maxSlots` | int | `5` |
| `dock.dragThreshold` | int | `50` |
| `dock.pinnedApps` | list of strings | empty |

## `launcher`

| Option | Type | Default |
| --- | --- | --- |
| `launcher.enabled` | bool | `true` |
| `launcher.showOnHover` | bool | `false` |
| `launcher.maxShown` | int | `7` |
| `launcher.maxWallpapers` | int | `9` |
| `launcher.specialPrefix` | string | `"@"` |
| `launcher.actionPrefix` | string | `">"` |
| `launcher.enableDangerousActions` | bool | `false` |
| `launcher.dragThreshold` | int | `50` |
| `launcher.vimKeybinds` | bool | `false` |
| `launcher.favouriteApps` | list of strings | empty |
| `launcher.hiddenApps` | list of strings | empty |

## `lock`

| Option | Type | Default |
| --- | --- | --- |
| `lock.enabled` | bool | `true` |
| `lock.useWallpaper` | bool | `false` |
| `lock.showGif` | bool | `true` |
| `lock.recolourLogo` | bool | `true` |
| `lock.enableFprint` | bool | `true` |
| `lock.maxFprintTries` | int | `3` |
| `lock.enableHowdy` | bool | `true` |
| `lock.maxHowdyTries` | int | `3` |
| `lock.triggerHowdyOnWake` | bool | `true` |
| `lock.enablePattern` | bool | `false` |
| `lock.hideNotifs` | bool | `false` |
| `lock.enableSessionControls` | bool | `false` |

## `nexus`

| Option | Type | Default |
| --- | --- | --- |
| `nexus.wallpapersPerRow` | int | `4` |
| `nexus.maxNetworksShown` | int | `5` |
| `nexus.networkRescanInterval` | int | `15000` |

## `notifs`

| Option | Type | Default |
| --- | --- | --- |
| `notifs.expire` | bool | `true` |
| `notifs.defaultExpireTimeout` | int | `5000` |
| `notifs.fullscreenExpireTimeout` | int | `2000` |
| `notifs.clearThreshold` | number | `0.3` |
| `notifs.expandThreshold` | int | `20` |
| `notifs.actionOnClick` | bool | `false` |
| `notifs.groupPreviewNum` | int | `3` |
| `notifs.openExpanded` | bool | `false` |

## `osd`

| Option | Type | Default |
| --- | --- | --- |
| `osd.enabled` | bool | `true` |
| `osd.hideDelay` | int | `2000` |
| `osd.enableBrightness` | bool | `true` |
| `osd.enableMicrophone` | bool | `false` |

## `services`

| Option | Type | Default |
| --- | --- | --- |
| `services.weatherLocation` | string | empty |
| `services.visualiserBars` | int | `60` |
| `services.audioIncrement` | number | `0.1` |
| `services.brightnessIncrement` | number | `0.1` |
| `services.maxVolume` | number | `1.0` |
| `services.smartScheme` | bool | `true` |
| `services.defaultPlayer` | string | `"Spotify"` |

## `session`

| Option | Type | Default |
| --- | --- | --- |
| `session.enabled` | bool | `true` |
| `session.dragThreshold` | int | `30` |
| `session.vimKeybinds` | bool | `false` |
| `session.icons.logout` | string | `"logout"` |
| `session.icons.shutdown` | string | `"power_settings_new"` |
| `session.icons.hibernate` | string | `"downloading"` |
| `session.icons.reboot` | string | `"cached"` |
| `session.commands.logout` | list of strings | `"logout"` |
| `session.commands.shutdown` | list of strings | `"poweroff"` |
| `session.commands.hibernate` | list of strings | `"hibernate"` |
| `session.commands.reboot` | list of strings | `"reboot"` |

## `sidebar`

| Option | Type | Default |
| --- | --- | --- |
| `sidebar.enabled` | bool | `true` |
| `sidebar.showOnHover` | bool | `false` |
| `sidebar.minHoverThreshold` | int | `200` |
| `sidebar.dragThreshold` | int | `80` |

## `utilities`

| Option | Type | Default |
| --- | --- | --- |
| `utilities.enabled` | bool | `true` |
| `utilities.maxToasts` | int | `4` |
| `utilities.quickToggles` | list | `built-in list` |
| `utilities.cards.keepAwake` | bool | `true` |
| `utilities.cards.recorder` | bool | `true` |
| `utilities.cards.quickToggles` | bool | `true` |

## `paths`

| Option | Type | Default |
| --- | --- | --- |
| `paths.themeName` | string | `"Nebula"` |
| `paths.wallpaperDir` | string | `~/Pictures/Wallpapers` |
| `paths.lyricsDir` | string | `~/Music/Lyrics/` |
| `paths.noNotifsPic` | string | `"root:/assets/dino.png"` |
| `paths.lockNoNotifsPic` | string | `"root:/assets/dino.png"` |

## `appearance`

Text, spacing, rounding and animation scales (`appearance.font.scale`, `appearance.padding.scale`,
`appearance.spacing.scale`, `appearance.rounding.scale`, `appearance.anim.durations.scale`; all default to 1) and the
font family and size of each text style (`appearance.font.body.family`, `appearance.font.body.medium.size`, ...).
Nexus > Look & feel and Display > Interface size change these for you.
