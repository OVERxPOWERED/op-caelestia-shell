# 🔒 Lock Screen & Security

The **Lock Screen & Security** system enhances Caelestia with multi-mode authentication, gesture unlock, power confirmation dialogs, and PAM crash resilience.

---

## ✨ Features

- **3x3 Touch & Mouse Gesture Pattern Unlock**: Unlock your desktop using an Android-style 3x3 pattern.
- **In-Settings Pattern Recording Dialog**: 2-step draw & confirm modal within Nexus Settings to easily set or change patterns.
- **Power Actions & Confirmation Dialog**: Safe confirmation popups for Shutdown, Reboot, Suspend, and Hibernate directly from the lock screen.
- **Biometric & Face Unlock Support**: Native configuration toggles and attempt limits for `fprintd` (fingerprint reader) and Howdy (infrared face unlock).
- **Hardened PAM Error Handling**: Crash-proof PAM authentication cycle that displays toast errors on failed attempts without disrupting the lock surface.

---

## 🎮 Pattern Recording Flow

1. Open **Nexus Settings** $\rightarrow$ **Lock screen**.
2. Enable **Pattern unlock**.
3. Click **Set pattern** next to *Record new pattern*.
4. Connect at least 4 dots on the 3x3 grid, then draw the same pattern a second time to confirm.
5. Click **Save Pattern**. Your pattern is hashed and stored securely.

---

## ⚙️ Configuration (`shell.json`)

```json
{
  "lock": {
    "enabled": true,
    "enablePattern": true,
    "patternHash": "...",
    "enableFprint": true,
    "maxFprintTries": 3,
    "enableHowdy": false,
    "maxHowdyTries": 3,
    "triggerHowdyOnWake": true,
    "useWallpaper": true,
    "recolourLogo": false
  }
}
```

### Options Reference

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enablePattern` | `boolean` | `false` | Enable 3x3 gesture pattern authentication mode. |
| `enableFprint` | `boolean` | `true` | Enable fingerprint reader authentication via `fprintd`. |
| `maxFprintTries` | `integer` | `3` | Maximum fingerprint attempts before locking to password mode. |
| `enableHowdy` | `boolean` | `false` | Enable infrared facial recognition via Howdy. |
| `maxHowdyTries` | `integer` | `3` | Maximum facial recognition attempts before locking to password mode. |
| `triggerHowdyOnWake` | `boolean` | `true` | Immediately trigger facial scan when the display wakes up. |
| `useWallpaper` | `boolean` | `true` | Display blurred desktop background behind the lock screen. |
| `recolourLogo` | `boolean` | `false` | Tint lock screen logo with active theme accent color. |
