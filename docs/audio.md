# 🔊 Per-App Audio & Stream Management

The **Audio Popout** provides control over master audio devices as well as individual application volume streams and playback routing.

---

## ✨ Features

- **Live Application Audio Streams**: Automatically discovers active audio streams (Firefox, Spotify, Discord, Games, MPV, etc.).
- **Individual Application Volume Sliders**: Adjust application sound levels independently of the master sink volume.
- **Individual Mute Toggles**: Instantly mute background tabs or loud applications with a single click.
- **Defensive Device Handling**: Null-safe stream filtering prevents shell crashes when Bluetooth headphones disconnect or PipeWire streams are re-routed.

---

## 🎯 Usage

1. Click the **Audio** icon in the status bar (or use your configured audio popout shortcut).
2. Under **Applications**, you will see all active audio streams.
3. Slide the bar to adjust volume or click the speaker icon to toggle mute.
4. Switch master output/input devices from the top device selectors.

---

## ⚙️ Configuration (`shell.json`)

```json
{
  "services": {
    "audioIncrement": 0.05,
    "maxVolume": 1.0,
    "defaultPlayer": "Spotify",
    "playerAliases": [
      {
        "from": "com.github.th_ch.youtube_music",
        "to": "YT Music"
      }
    ]
  }
}
```
