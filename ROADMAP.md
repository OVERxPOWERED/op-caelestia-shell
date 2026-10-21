# OP-Caelestia Roadmap (`ROADMAP.md`)

The working plan for turning this fork (`op-caelestia-shell`) into a desktop that feels finished, reliable, and personal. It records what we decided, why, and what comes next.

- **Last updated**: 2026-10-21
- **Device**: MSI Modern 14 C12M: i5-1235U, Iris Xe, 16 GB RAM, 14" 1920x1080 panel at scale 1
- **Stack**: Arch Linux, Hyprland 0.56 (Lua config), Quickshell 0.3.2, this fork
- **Status legend**: `[ ]` pending, `[/]` in progress, `[x]` done, `[~]` parked

The earlier deep diagnostic audit (84 subphases, all complete) now lives in [`docs/diagnostic-roadmap.md`](./docs/diagnostic-roadmap.md), with its tracker in [`COMPLETION.md`](./COMPLETION.md) and its findings in [`DISCOVERY.md`](./DISCOVERY.md). The separate desktop-completeness gap analysis is in [`docs/desktop-environment-roadmap.md`](./docs/desktop-environment-roadmap.md).

---

## 1. Why this roadmap exists

Someone said the setup "looks cheap, unprofessional, incomplete, things do not click together." When we dug in, the criticism turned out to be about **bugs and glitches** (things not responding, shell crashes, Wi-Fi and Bluetooth trouble, visual glitches), not about the art style. So:

1. **Reliability comes first** (Track 1).
2. **Look and feel gets refined, not replaced** (Track 2). The character themes stay. Every visual change is opt-in.
3. **Something new**: control the laptop from the phone, natively (Track 3).

---

## 2. Working principles

These apply to every item below.

| # | Principle | In practice |
|---|---|---|
| P1 | **Stable stays stable** | Work happens in `caelestia-underWork`. `caelestia-stable`, which Hyprland launches, only changes after you approve. |
| P2 | **Visual changes are opt-in** | Each look-and-feel change sits behind a config option you can flip, and comes with before/after screenshots. Nothing changes the look without your approval. Rejected options get removed for good; liked ones get improved. |
| P3 | **Keep syncing upstream** | Changes stay small, isolated, config-gated, and easy to rebase onto `caelestia-dots/shell`. Prefer new files and config over deep rewrites of upstream files. |
| P4 | **Verify before claiming** | Before calling something broken, trace the shell's own code path and confirm it in `journalctl` or in a reproduction. Anything unverified is phrased as a question. |
| P5 | **Themes stay as they are** | The 8 hand-made character themes in `assets/themes/` and their folder format stay unchanged. No theme-pack redesign, so making new themes doesn't get harder. |
| P6 | **Keyboard first** | You drive the desktop almost entirely from the keyboard. Every new feature needs a keyboard path, and mouse/hover paths come second. |
| P7 | **One small step at a time** | One item per commit or series, then you review it before the next starts. |

---

## 3. Decisions log

| Date | Decision |
|---|---|
| 2026-10-21 | The criticism was about bugs and glitches, so reliability is the top priority. |
| 2026-10-21 | Character themes stay central and the theme format is unchanged. |
| 2026-10-21 | The UI feels **too big** (shell UI, spacing and chrome, app content). We make it smaller by tuning live, not with a fixed value. |
| 2026-10-21 | Glass and transparency stay as they are by default. Possible refinements are shown as switchable examples. |
| 2026-10-21 | Keep syncing upstream. |
| 2026-10-21 | Review flow: switchable options plus before/after screenshots. |
| 2026-10-21 | New directions chosen: self-healing "Doctor", signature motion, phone control app. |
| 2026-10-21 | Phone app: Android first, iOS next. Scope is **everything**, using the hybrid model (native controls plus per-window streaming), with limits mapped honestly (see Track 3). |
| 2026-10-21 | Displays: Nexus front-end with hyprmoncfg as the engine; fix the Hyprland include with a backup; plug-in chooser popup. Search: every individual setting. |
| 2026-10-21 | `DIAGNOS_RDMP.md` became this `ROADMAP.md`. The old content was kept in `docs/diagnostic-roadmap.md`. |

### Withdrawn findings from the first analysis

These were wrong and must not come back:

- ~~"Idle sleep never fires because hibernate is unavailable."~~ `SessionManager::suspendThenHibernate()` (`plugin/src/Caelestia/Services/sessionmanager.cpp:108`) falls back to plain suspend, and the journal shows the shell's suspends working.
- ~~"The laptop is unlocked after closing the lid."~~ It locks through the shell's own lock screen, which is a deliberate choice over SDDM. The shell also holds a "Lock screen before sleep" delay inhibitor.
- ~~"Increase the screen scale to 1.25."~~ The opposite is wanted: everything should get smaller.

---

## 4. Track 1: Reliability

The goal is that nothing breaks in front of other people. Order: 1.1, then 1.2, 1.3, 1.4, 1.5.

### `[/]` 1.1 Bluetooth agent leak (pairing fails, headphones won't connect)

- **Evidence (2026-10-21)**: 8 `bt-agent.py` processes were running. Only one (PID 1603224) belongs to the current shell. The other 7 were re-parented to PID 1126, one per shell restart since Oct 16, and all use the same `$XDG_RUNTIME_DIR/caelestia-bt-agent.sock`. `bluetoothd` logs `a2dp-sink profile connect failed ... Device or resource busy` and `Reconnecting services failed: Operation already in progress` for `98:47:44:BC:92:42`.
- **Likely cause**: `scripts/startup-shell.sh` restarts the shell with `killall -9 quickshell`. SIGKILL gives the shell no chance to stop its child processes, so each old agent keeps running. When a pairing request goes to a leftover agent, its prompt has no UI to show in. *Likely, not proven yet.*
- **Plan**:
  1. Make `bt-agent.py` single-instance: hold a lock file or the socket, and exit if another live agent owns it.
  2. Have the agent exit when its parent dies (watch the parent PID, or use `PR_SET_PDEATHSIG`).
  3. Restart the shell with SIGTERM first and SIGKILL only as a fallback.
  4. Clean up the 7 leftovers.
- **Progress (2026-10-21)**: Steps 1–4 are implemented in `underWork` (`scripts/bt-agent.py`, `scripts/startup-shell.sh`) and not committed. A new agent takes over from a previous one through a lock file in `$XDG_RUNTIME_DIR`. Each agent exits when its parent dies (`PR_SET_PDEATHSIG` plus a 2-second parent check). An agent only removes the socket file if it still owns it; before, an old agent's cleanup deleted the live agent's socket. The 7 leftover agents were force-killed. Takeover and parent-death were tested in isolation. First run under the real shell failed with `Address already in use`: my edit had removed the stale-socket cleanup from `start()` (fixed). After the fix, the underWork shell runs exactly one agent parented to it, and killing that agent makes the shell respawn exactly one replacement. **Still to do**: restart the shell with the new `startup-shell.sh` several times and confirm one agent each time, pair a device, reconnect the headphones, then copy to `caelestia-stable` with your approval.
- **Done when**: after 5 shell restarts there is exactly one agent, pairing a new device shows the prompt, and the headphones connect on the first try.

### `[/]` 1.2 Wi-Fi in the shell (networks missing, correct password fails)

- **Symptoms**: Sometimes networks don't show up. Sometimes the correct password still fails to connect. Seeing networks or connecting currently needs `nmtui`.
- **Plan**:
  1. Reproduce with logging on: the shell's `services/Nmcli.qml` and the bar and Nexus Wi-Fi flows (`modules/bar/popouts/Network.qml`, `WirelessPassword.qml`, `modules/nexus/pages/NetworkPage.qml`), alongside `journalctl -u NetworkManager`.
  2. Check scan triggering and refresh: whether a rescan is requested, whether stale results are cached, and how results parse.
  3. Check the connect path: how the password is passed, existing vs. new connection profiles, wrong key management (`key-mgmt`), hidden networks, and whether NetworkManager's error ever reaches the UI.
  4. Show clear errors in the UI ("wrong password", "network out of range", "timed out") instead of failing silently.
- **Findings (2026-10-21)**:
  1. Saved-profile connects had a null callback (`utils/NetworkConnection.qml`), so a stale password failed silently: no dialog and no error. This is the likeliest reason a "correct" password seemed not to work.
  2. `nmcli device wifi connect <ssid> password <pw>` creates a new profile when one exists. The machine had pairs like `iPhone` / `iPhone 1` and `Lab09wifi1` / `Lab09wifi1 1`, with the old profile keeping its stale key.
  3. SSIDs were trimmed, so a network called `"Samsung "` (trailing space) could never be matched.
  4. While connected, the Intel card returns few access points per scan, and the list shrank between scans (6, 5, 4 networks). The forced rescan also blocks about 11 seconds.
  5. Not a cause: the regulatory domain. The chip's firmware already reports country IN.
- **Implemented in `underWork` (not committed)**: `scripts/wifi-connect.sh` reuses and updates the saved profile and reports why a connect failed (exit 10 password needed, 11 rejected, 12 not found); the password travels in the environment, not on the command line. `services/Nmcli.qml` uses it, matches SSIDs exactly, and keeps an unseen access point for 45 seconds. `NetworkConnection.qml` always opens the password dialog or shows a toast on failure. Tested the script directly: wrong password gives 11 with no duplicate profile, an unknown network gives 12, the current network gives 0. **Still to test in the UI** by you, then the duplicate-profile cleanup (proposed for Doctor, 1.5).
- **Done when**: across 10 tries (scan, then connect to a known and a new network), the shell matches `nmcli dev wifi list` and never needs `nmtui`.

### `[/]` 1.3 Displays in Nexus (HDMI, projector mirroring), built on hyprmoncfg

- **Symptoms**: A mirrored image is cropped or zoomed on projectors, and the shell looks too big or too small on the external screen.
- **Decisions (2026-10-21)**: Nexus becomes the front-end and **hyprmoncfg stays the engine** (apply/save/profiles, mirroring, confirm-or-revert timer, lid handling, workspace rules). Its terminal UI keeps working. Plugging in a display opens a **quick chooser** (Mirror / Extend / External only / Laptop only); displays with a saved profile apply it automatically.
- **Findings**:
  1. `hyprmoncfg doctor` reports Hyprland does **not** load hyprmoncfg's generated file (`~/.config/hypr/hyprmoncfg-monitors.lua` doesn't exist), so applying or saving profiles had no effect on startup. `monitors.lua` is a hand copy, and `hyprland.lua` repeats its workspace rules.
  2. `~/.config/hypr` is a symlink to `~/.local/share/caelestia/hypr`.
  3. Your saved profile `2-Mon-R-Ex` (updated Sep 20) puts workspace 1 on the Samsung and 2 on the laptop. `hyprland.lua` and `monitors.lua` do the opposite. Applying that profile changes your workspace-to-monitor assignment.
  4. hyprmoncfg 1.25 can express mirroring, rotation and HDR; Hyprland's `mirror` works (`mirrorOf` is reported live). I could **not** capture the mirrored picture to see the crop: `grim` can't see a mirrored output. The crop cause is unconfirmed.
- **Done so far**: backups at `~/.config/hypr-backup-2026-10-21-before-hyprmoncfg.tar.gz` (follows the symlink) and `~/.config/hypr-backup-2026-10-21-hyprland.lua.original`. hyprmoncfg appended its `dofile` include to the end of `hyprland.lua` (a no-op until the generated file exists). `require("monitors")` and the duplicate workspace rules are **still in place**, so nothing changed in behaviour.
- **My test mess (resolved)**: the temporary headless output `HEADLESS-1` I created could not be removed while disabled, and a config reload re-enabled it as a ghost screen. `hyprctl output remove HEADLESS-1` works while the output is enabled; it is gone now. Lesson: remove test outputs while they are enabled.
- **Plan**:
  1. After the next Hyprland restart: save a `Laptop-Only` profile, check the JSON, apply it with the revert timer, then remove `require("monitors")` and the duplicated workspace rules from `hyprland.lua`.
  2. Nexus **Display** page (the commented-out "Display" entry in `PageRegistry.qml`): a drag-to-arrange canvas, per-display mode, scale, rotation, mirror and enable, profile list (apply/save/delete), and a "Keep these settings?" countdown driven by hyprmoncfg's own timer.
  3. Plug-in chooser in the shell, listening for Hyprland monitor events; keyboard first.
  4. Per-monitor shell size from each display's own config (`~/.config/caelestia/monitors/<output>/shell.json`).
  5. Mirror crop: reproduce on a real projector or a safe virtual display, then decide between mirroring at the projector's native mode or setting the laptop panel to a mode the projector supports.
- **Done when**: plugging into the Samsung and a 1366x768 or 1024x768 display gives an uncropped mirror, a correctly sized shell, and no workspaces or windows jumping around, all controlled from Nexus.

### `[ ]` 1.4 Small visible bugs

| Bug | Where | Fix |
|---|---|---|
| Overview header shows "2 2" | `modules/overview/components/WorkspaceCard.qml:138` and `:147`: the number badge plus `name`, which equals the id for numbered workspaces | Hide the name when it equals `String(id)` |
| Text cut off: "Hyprland..." (dashboard user card), "Screen rec..." (sidebar recorder card) | dashboard and utilities cards | Fit the text, shorten the labels, or reflow the layout |
| Further glitches you spot | — | Add them to this table as they appear |

### `[ ]` 1.5 "Doctor": a self-healing page in Nexus

Turns Track 1 into something permanent instead of a one-time cleanup.

- **Detects**:
  - duplicate or orphaned helper processes (bt-agent and others)
  - NetworkManager or BlueZ not running or in a bad state
  - Wi-Fi radio blocked (`rfkill`)
  - monitors without a config
  - a missing portal or polkit agent
  - recent shell crashes (`coredumpctl`, `~/.cache/quickshell/crashes`)
- **Fixes with one action**: restart a service, kill orphans, re-scan, reset a Bluetooth device, reapply the monitor layout.
- **Watchdog**: background checks that raise a quiet toast when something drifts.
- **Done when**: every Track 1 issue above would have been caught and offered a fix by Doctor.

### `[/]` 1.6 Nexus search (does nothing today)

- **Finding**: the search box in `modules/nexus/NavPane.qml` only sets `nState.searchOpen`; nothing in the codebase reads it. Upstream Caelestia has the same empty hook, so this is an unfinished feature, not a regression.
- **Decision (2026-10-21)**: search **every individual setting**, with synonyms ("wifi" finds Network).
- **Plan**:
  1. A settings index: page, subpage, row label, description and keywords, kept next to each page so it cannot drift. Start from `PageRegistry.qml` and the page files.
  2. Results list replaces the page area while you type; Enter or click opens the page and highlights the row; Esc clears. `Ctrl+F` or `/` focuses the search box (keyboard first).
  3. Rank by label match, then keywords, then page name; fuzzy matching optional.
  4. A check that fails when a page has rows missing from the index.
- **Implemented in `underWork` (not committed)**: `scripts/gen-nexus-search-index.py` builds `modules/nexus/SearchIndex.qml` from the page files (213 entries: 38 pages and sub-pages, 175 settings) and reuses the same `Tr.tr(...)` expressions as the pages, so translations match. `modules/nexus/SearchEngine.qml` ranks (exact, prefix, word start, substring, keyword, section, description, loose match; every word must match; phrase keywords such as "dark mode"). `SearchResults.qml` replaces the page while you type. Keys: `Ctrl+F` focuses search; Up/Down move; Enter opens; Esc clears. `PageBase.qml` scrolls to the chosen row and flashes it. Extra keywords: `scripts/nexus-search-keywords.json`. Run `scripts/gen-nexus-search-index.py` after changing Nexus pages; `--check` fails if the index is stale.
- **Tested live** (synthetic keystrokes in the running shell): "wifi" ranks the Wi-Fi row first; Enter on a Services result and on a Panels › Utilities result both land on the right page and highlight the row; no-results state; Esc clears. Not reproduced: one early run that landed on Panels › Dashboard instead (right after a hot reload of my own edits).
- **Known gaps**: sub-pages that need a selected device, network or app (device info, network details, app info, wallpaper category) are not searchable; rows with dynamic text (containing `%`) are skipped; one "Browse" button is missing from the index.
- **Done when**: typing "idle", "dock", "wifi" or "mirror" lists the right settings and Enter lands on the highlighted row. "mirror" waits for the Display page (1.3).

---

## 5. Track 2: Look and feel (opt-in options)

Each item ships behind config options, with before/after screenshots, following P2. Defaults keep today's look.

### `[ ]` 2.1 Density: make things smaller, tuned live

You want to tune this live rather than get a fixed number.

- **Shell**: the existing scale settings in `shell.json`: `appearance.font.scale`, `appearance.padding.scale`, `appearance.spacing.scale`, `appearance.rounding.scale`, plus the screen-border `thickness` and `rounding`.
- **Window chrome**: the Hyprland variables in `~/.config/hypr/variables.lua` (`windowGapsIn` / `windowGapsOut` / `workspaceGaps` / `singleWindowGapsOut`, `windowBorderSize`).
- **App content**:
  - GTK: `org.gnome.desktop.interface text-scaling-factor`
  - Qt: font size in qt6ct and qt5ct
  - Chromium and Electron (Chrome, Claude, WhatsApp, Obsidian, VS Code): `--force-device-scale-factor` or per-app zoom
- **Deliverable**: a "Density" section in Nexus with live sliders, plus three named presets: **Comfortable** (today's look), **Compact**, and **Dense**. You fine-tune from there.
- **Done when**: you have picked values you're happy with.

### `[ ]` 2.2 Glass: examples you can compare

You're happy with the glass today. These are examples only, each one switchable:

- **Overview background blur**: the overview's layer is named `caelestia-overview`, but the Hyprland blur rule only matches `caelestia-(drawers|quicknote)`, so its "Blurred Glassmorphic Backdrop" (`modules/overview/OverviewContent.qml`) isn't actually blurred. Option: add a blur rule plus a slightly stronger dim behind it.
- **Readability**: a version where only text-heavy app windows become opaque, compared against today's `windowOpacity = 0.92`.
- More examples get added here as we find them. Each is kept or dropped after you see it.

### `[ ]` 2.3 Signature motion

One consistent animation style for the whole shell: opening, closing, morphing, and moving between surfaces.

- Replace the roughly 63 hard-coded `duration:` values in QML with the shared animation tokens (`Tokens.anim.*`).
- Match Hyprland's window, workspace and layer curves (`~/.config/hypr/hyprland/animations.lua`) to the shell's curves, so windows and panels move the same way.
- Define the style in one place, so a future theme *could* override it without changing any theme folders (P5).
- **Done when**: side-by-side recordings show every surface moving the same way, and you prefer it.

### `[ ]` 2.4 App font consistency (to show you, not to impose)

- **Evidence**: there is no user fontconfig file, so the generic `sans-serif` and `monospace` names resolve to **Noto Sans CJK KR** and **Noto Sans Mono CJK KR**. Qt apps (qt6ct `"Sans Serif"`) and Chromium/Electron apps therefore render in a Korean CJK font, GTK uses Adwaita Sans, and the shell uses Google Sans Flex, which it loads only for itself (`modules/GSFLoader.qml`).
- **Option**: a fontconfig file mapping `sans-serif` and `monospace` to fonts you choose, with screenshots of apps before and after.

---

## 6. Track 3: Phone control app ("OP Remote", working name)

### 6.1 Vision

Use the laptop from the phone **the way you naturally use the phone**, not by looking at a mirrored laptop screen. Open laptop apps, use them, manage windows, control the system, move files and clipboard, type and point. The scope is everything. This section maps what is possible, what is hard, and what can't be done, so we build something real.

### 6.2 What this laptop can do (checked 2026-10-21)

| Capability | How | Status on this machine |
|---|---|---|
| List, launch, focus, close and move windows and workspaces | Hyprland IPC socket and `hyprctl`, `.desktop` entries | Available |
| Capture a **single window** | `ext_foreign_toplevel_image_capture_source_manager_v1` + `ext_image_copy_capture_manager_v1`, or `hyprland_toplevel_export_manager_v1` | **Supported by your Hyprland build** |
| Capture a whole output | `zwlr_screencopy_manager_v1` / PipeWire | Supported |
| Create phone-shaped virtual displays | `hyprctl output create headless` | Already used here (HEADLESS-2..5 configs exist) |
| Inject keyboard and pointer input without root | `zwp_virtual_keyboard_manager_v1`, `zwlr_virtual_pointer_manager_v1` | **Supported**. Fallback: `/dev/uinput` (you're in `input`, `ydotool` installed) |
| Hardware video encode (H.264/HEVC) | Intel QSV/VA-API via `intel-media-driver` (iHD) | Driver installed. **Missing**: `gst-plugin-va` (or the ffmpeg VA-API path), `gst-plugin-pipewire`, `libva-utils` to verify |
| WebRTC media pipeline | GStreamer `webrtcbin` | Available (`gst-plugins-bad` 1.28) |
| Media, volume, brightness, Wi-Fi, Bluetooth, power, lock | MPRIS, PipeWire/`wpctl`, the shell's `qs ipc` targets (`mpris`, `brightness`, `lock`, `drawers`, `notifs`, …), NetworkManager, BlueZ, logind | Available |
| Clipboard | `wl-clipboard` (`wl-paste --watch`), already used for `cliphist` | Available |
| Keep the laptop awake with the lid closed during a session | logind `handle-lid-switch` + `sleep` inhibitor locks | Supported (inhibitors are in use already) |
| Private network | Tailscale | Laptop online. **Note**: the Android nodes on your tailnet are all offline (49–233 days). Check that your current phone is signed in |
| Toolchains | Rust/Cargo, Go, Java, Android SDK + `adb` | Installed. **Missing**: Flutter (if chosen) |

### 6.3 Honest limits

| Limit | Why | What we do about it |
|---|---|---|
| Laptop asleep or off = unreachable | Wake-on-LAN over Wi-Fi is unreliable on most laptops | Keep the laptop awake while a session is active (inhibitor). Test Wake-on-WLAN later as an experiment |
| One keyboard focus at a time | Hyprland has one input seat, so the phone and someone at the laptop can't type into different apps at once | A "remote session" mode: the phone takes focus, and the laptop shows a small "controlled from phone" indicator |
| Native UIs can't reach *inside* arbitrary apps | Apps don't expose their internals | Hybrid model: native phone UI for system-level things, **per-window streaming** when you open an app. Stretch goal: read an app's UI through the accessibility tree (AT-SPI) and render parts of it natively on the phone, which only works for some GTK/Qt/Chromium apps |
| A locked laptop must stay secure | Remote unlock is a real attack surface | No bypass, ever. Open decision D4 below |
| Streaming costs power and heat | Video encode on a 15 W CPU | Hardware encode, adaptive bitrate, stream only while visible |
| Off home Wi-Fi, latency grows | Tailscale may relay traffic (DERP) | Fine for controls. Streaming adapts its quality |

### 6.4 Interaction model: hybrid (decided)

1. **Native phone UI** for everything system-level: app launcher, window and workspace switcher, media, volume, brightness, Wi-Fi and Bluetooth, notifications, files, clipboard, power and lock. Fast, works offline-tolerant, and feels like a phone app.
2. **Per-window streaming** when you open an app. The key idea: move the app onto a **phone-shaped virtual display** sized to the phone's resolution and scale. The app then lays itself out *for the phone* (it is not a shrunk laptop window) and runs on the laptop. Touch maps to absolute pointer and gestures, the phone keyboard maps to the virtual keyboard, and you can send the app back to the laptop screen at any time.
3. **Keyboard and touchpad mode** for anything else: the phone becomes a trackpad and keyboard for the real laptop screen.

### 6.5 Architecture (proposed)

```
 Phone (Android, later iOS)                     Laptop
┌──────────────────────────┐   Tailscale    ┌──────────────────────────────────────┐
│ OP Remote app            │  (WireGuard)   │ op-remoted (user service, systemd)   │
│  • Native screens        │◄──────────────►│  • Control API: WebSocket, JSON-RPC  │
│  • Window viewer (video) │  control: WS   │  • Media: WebRTC (GStreamer, VA-API) │
│  • Touch/keys → input    │  media: WebRTC │  • Input: virtual kbd/pointer        │
│  • Share sheet, files    │                │  • Adapters ─┬─ Hyprland IPC         │
└──────────────────────────┘                │              ├─ D-Bus: NM, BlueZ,    │
                                            │              │  logind, MPRIS, notifs│
                                            │              ├─ PipeWire / wpctl     │
                                            │              ├─ wl-clipboard         │
                                            │              ├─ filesystem (scoped)  │
                                            │              └─ shell: `qs ipc call` │
                                            └──────────────────────────────────────┘
                                              Shell shows "phone connected" in the
                                              bar and in Doctor.
```

- **The daemon lives outside the Quickshell tree**, in its own repository. It survives shell restarts and doesn't touch upstream files (P3). The shell only adds a small status indicator and Doctor checks.
- **Security**:
  - Listen only on the Tailscale interface.
  - Verify each peer with Tailscale's LocalAPI `whois`: it must be one of *your* devices.
  - Pair once with a device key (scan a QR code).
  - Per-device permissions: control, files, input, streaming.
  - Keep an audit log.

### 6.6 Recommended stack (proposed, confirm in D1/D2)

| Part | Recommendation | Why |
|---|---|---|
| Laptop daemon | **Rust** (tokio, axum, gstreamer-rs, wayland-client / smithay-client-toolkit, zbus) | Long-running and memory-safe. First-class bindings for Wayland protocols, GStreamer and D-Bus. Your C++ plugin experience carries over |
| Phone app | **Flutter** | One codebase for Android now and iOS next. Mature WebRTC (`flutter_webrtc`). Material 3, which matches the shell |
| Control protocol | Versioned JSON-RPC over WebSocket, plus an event stream | Simple and debuggable. Commands and events in one schema shared by both sides |
| Media and input | WebRTC (video track + data channel for input) | Low latency, NAT-friendly, adaptive bitrate |

### 6.7 Phases

Each phase ends with something you can actually use.

| Phase | Deliverable | Done when |
|---|---|---|
| `[ ]` **3.0 Spikes** | Prove the three hard parts: (a) capture one window on Hyprland, (b) hardware encode and stream it to the phone over Tailscale, (c) inject keys and pointer input onto a headless output. Install the missing packages | Latency and quality are measured and acceptable on your phone |
| `[ ]` **3.1 Foundation** | Daemon as a systemd user service, pairing, Tailscale-only security, the app skeleton, "phone connected" in the shell | The phone pairs and sees the laptop's status |
| `[ ]` **3.2 Native controls** | App launcher (with icons), window and workspace list (focus, close, move), media, volume, brightness, Wi-Fi/BT, lock/sleep/power, laptop notifications on the phone | You can run your day-to-day laptop controls from the phone |
| `[ ]` **3.3 Keyboard and touchpad** | Trackpad gestures, keyboard with modifiers and shortcuts, text entry | You can drive the real laptop screen from the phone comfortably |
| `[ ]` **3.4 Files and clipboard** | Browse folders you allow, upload and download, Android share sheet to "send to laptop", two-way clipboard sync | Moving a photo or text either way takes one action |
| `[ ]` **3.5 Apps on the phone** | Phone-shaped virtual display, open a laptop app in it, touch and keyboard input, send it back to the laptop | You can use, say, Obsidian or Spotify on the phone with a phone-sized layout |
| `[ ]` **3.6 Beyond** | Terminal on the phone (shell session over the same connection), phone as webcam/mic for the laptop, replying to notifications, automations ("start study session"), the AT-SPI native-UI experiment | Each feature is its own small item |
| `[ ]` **3.7 iOS** | Port the Flutter app and handle iOS background limits | Feature parity for 3.1–3.5 |

### 6.8 Open decisions (my recommendation in **bold**)

- **D1 Daemon language**: **Rust** / Go / Python.
- **D2 App framework**: **Flutter** / native Kotlin (and Swift later) / React Native.
- **D3 Repo**: **a new repository** (for example `op-remote`, with daemon and app as a monorepo) / inside this shell repo.
- **D4 Remote unlock**: **allowed only with the phone's biometric check plus your password, typed on the phone and passed to the shell's own lock screen (through PAM, never bypassed)** / never unlock remotely.
- **D5 Lid closed during a session**: **keep running with the laptop screen off** / suspend as usual.
- **D6 Laptop screen while streaming an app**: **leave it as is, with a "controlled from phone" indicator** / blank the laptop screen for privacy.
- **D7 Name**: "OP Remote" is a placeholder.

---

## 7. Parked ideas

Suggested but not chosen this round. Kept here so they aren't lost.

- `[~]` Dynamic island: a live pill in the bar for timer, music, recording, downloads
- `[~]` Presentation-safe mode: automatic when mirroring or screen sharing; hides notifications
- `[~]` Study cockpit: Pomodoro + focus mode + lecture/PDF layout + per-subject progress
- `[~]` Quick Look / peek previews
- `[~]` Easy theme maker / theme inheritance (declined for now under P5)
- `[~]` "Living themes" with sounds and motion per theme. Interesting, but needs more thought about keeping themes light
- `[~]` Session snapshots, ActivityWatch timeline, universal search, smart notifications. Not reviewed yet

---

## 8. Next step

Start **1.1 (Bluetooth agent leak)** in `caelestia-underWork`, then verify it per its "done when". In parallel, before any code is written for Track 3, confirm D1–D7.
