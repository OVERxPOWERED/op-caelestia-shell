# ⚙️ Configuration Reference (`shell.json`)

All shell customization settings are defined in `~/.config/caelestia/shell.json`.

---

## 📄 Complete Example Configuration

```json
{
  "dock": {
    "enabled": true,
    "showOnHover": true,
    "maxSlots": 10,
    "dragThreshold": 20,
    "pinnedApps": [
      "firefox.desktop",
      "thunar.desktop",
      "foot.desktop"
    ]
  },
  "overview": {
    "defaultTab": "carousel",
    "showSpecialWorkspaces": true,
    "scale": 1.0
  },
  "lock": {
    "enabled": true,
    "showGif": true,
    "enablePattern": false,
    "pattern": "74159",
    "enableFprint": true,
    "maxFprintTries": 3,
    "enableHowdy": false,
    "maxHowdyTries": 3,
    "triggerHowdyOnWake": true,
    "useWallpaper": true,
    "recolourLogo": false
  },
  "background": {
    "enabled": true,
    "wallpaperEnabled": true,
    "desktopClock": {
      "enabled": false
    },
    "visualiser": {
      "enabled": false,
      "autoHide": true,
      "blur": false,
      "rounding": 1,
      "spacing": 1
    }
  },
  "general": {
    "battery": {
      "criticalLevel": 3
    },
    "idle": {
      "inhibitWhenAudio": true,
      "inhibitWhenCharging": false,
      "lockBeforeSleep": true,
      "timeouts": [
        {
          "timeout": 180,
          "idleAction": "lock"
        },
        {
          "timeout": 300,
          "idleAction": "dpms off",
          "returnAction": "dpms on"
        },
        {
          "timeout": 600,
          "idleAction": ["suspendThenHibernate"]
        }
      ]
    }
  },
  "osd": {
    "enabled": true,
    "hideDelay": 2000,
    "enableBrightness": true,
    "enableMicrophone": false
  },
  "paths": {
    "wallpaperDir": "~/Pictures/Wallpapers"
  },
  "services": {
    "audioIncrement": 0.05,
    "maxVolume": 1.0,
    "smartScheme": true,
    "defaultPlayer": "Spotify",
    "playerAliases": [
      {
        "from": "com.github.th_ch.youtube_music",
        "to": "YT Music"
      }
    ]
  },
  "utilities": {
    "enabled": true,
    "quickToggles": [
      { "id": "wifi", "enabled": true },
      { "id": "bluetooth", "enabled": true },
      { "id": "mic", "enabled": true },
      { "id": "settings", "enabled": true },
      { "id": "gameMode", "enabled": true },
      { "id": "dnd", "enabled": true },
      { "id": "vpn", "enabled": false },
      { "id": "hotspot", "enabled": true }
    ]
  }
}
```
