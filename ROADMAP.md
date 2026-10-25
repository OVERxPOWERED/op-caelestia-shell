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
4. **Config in Nexus** (Track 4, added 2026-10-24): the Hyprland config files become settings you can change from Nexus.

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
| 2026-10-24 | The Wi-Fi hotspot feature is dropped for now and will not be ported; it can be attempted again later from scratch. The leftover NetworkManager profile was deleted. |
| 2026-10-24 | The new branch will become `main` after the uncommitted work is committed, using a history-preserving merge (no force-push) and a backup tag of the old `main`. |
| 2026-10-21 | `DIAGNOS_RDMP.md` became this `ROADMAP.md`. The old content was kept in `docs/diagnostic-roadmap.md`. |

### Withdrawn findings from the first analysis

These were wrong and must not come back:

- ~~"Idle sleep never fires because hibernate is unavailable."~~ `SessionManager::suspendThenHibernate()` (`plugin/src/Caelestia/Services/sessionmanager.cpp:108`) falls back to plain suspend, and the journal shows the shell's suspends working.
- ~~"The laptop is unlocked after closing the lid."~~ It locks through the shell's own lock screen, which is a deliberate choice over SDDM. The shell also holds a "Lock screen before sleep" delay inhibitor.
- ~~"Increase the screen scale to 1.25."~~ The opposite is wanted: everything should get smaller.

---

## 4. Track 1: Reliability

The goal is that nothing breaks in front of other people. Order: 1.1, then 1.2, 1.3, 1.4, 1.5.

### `[x]` 1.1 Bluetooth agent leak (pairing fails, headphones won't connect)

- **Evidence (2026-10-21)**: 8 `bt-agent.py` processes were running. Only one (PID 1603224) belongs to the current shell. The other 7 were re-parented to PID 1126, one per shell restart since Oct 16, and all use the same `$XDG_RUNTIME_DIR/caelestia-bt-agent.sock`. `bluetoothd` logs `a2dp-sink profile connect failed ... Device or resource busy` and `Reconnecting services failed: Operation already in progress` for `98:47:44:BC:92:42`.
- **Likely cause**: `scripts/startup-shell.sh` restarts the shell with `killall -9 quickshell`. SIGKILL gives the shell no chance to stop its child processes, so each old agent keeps running. When a pairing request goes to a leftover agent, its prompt has no UI to show in. *Likely, not proven yet.*
- **Plan**:
  1. Make `bt-agent.py` single-instance: hold a lock file or the socket, and exit if another live agent owns it.
  2. Have the agent exit when its parent dies (watch the parent PID, or use `PR_SET_PDEATHSIG`).
  3. Restart the shell with SIGTERM first and SIGKILL only as a fallback.
  4. Clean up the 7 leftovers.
- **Progress (2026-10-21)**: Steps 1–4 are implemented in `underWork` (`scripts/bt-agent.py`, `scripts/startup-shell.sh`) and not committed. A new agent takes over from a previous one through a lock file in `$XDG_RUNTIME_DIR`. Each agent exits when its parent dies (`PR_SET_PDEATHSIG` plus a 2-second parent check). An agent only removes the socket file if it still owns it; before, an old agent's cleanup deleted the live agent's socket. The 7 leftover agents were force-killed. Takeover and parent-death were tested in isolation. First run under the real shell failed with `Address already in use`: my edit had removed the stale-socket cleanup from `start()` (fixed). After the fix, the underWork shell runs exactly one agent parented to it, and killing that agent makes the shell respawn exactly one replacement. **Still to do**: restart the shell with the new `startup-shell.sh` several times and confirm one agent each time, pair a device, reconnect the headphones, then copy to `caelestia-stable` with your approval.
- **Done when**: after 5 shell restarts there is exactly one agent, pairing a new device shows the prompt, and the headphones connect on the first try.

### `[x]` 1.2 Wi-Fi in the shell (networks missing, correct password fails)

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
- **Done so far**:
  - Backups: `~/.config/hypr-backup-2026-10-21-before-hyprmoncfg.tar.gz` (follows the symlink) and `~/.config/hypr-backup-2026-10-21-hyprland.lua.original`.
  - hyprmoncfg's `dofile` include is at the end of `hyprland.lua`; `hyprmoncfg doctor` reports OK and the generated file `~/.config/hypr/hyprmoncfg-monitors.lua` now exists (laptop panel only, saved as the profile `Auto eDP-1`).
  - **Display page built** (`modules/nexus/pages/DisplayPage.qml`, `common/DisplayArrangement.qml`, `services/Displays.qml`): quick layouts (Extend, Mirror, External only, Laptop only), a drag-to-arrange map with edge snapping and overlap protection, per-display enable, resolution, refresh rate, scale, rotation, mirror and position, saved profiles (apply, save), and a "Keep these display settings?" banner with a 15 s countdown. Unconfirmed changes revert by themselves; only a kept layout is written to hyprmoncfg. If the shell restarts mid-confirmation, the pending change is offered again.
  - `qs ipc call displays ...` (`layout`, `mirror`, `enable`, `scale`, `keep`, `revert`, `status`) so layouts can be bound to keys.
- **Findings while building it**:
  1. Hyprland cannot change mirroring on a live output: `hl.monitor` only applies `mirror` the first time an output gets a rule, and un-mirroring does nothing until a config reload. `hyprctl keyword` is refused in Lua mode. So mirror changes go through a hyprmoncfg profile (`scripts/display-draft.py` edits a draft profile, `hyprmoncfg apply` writes the file and reloads); everything else applies live with `hyprctl eval`.
  2. A disabled monitor is only re-enabled by a rule that says `disabled = false`; a normal rule is ignored.
  3. Presets deliberately ignore virtual outputs (`HEADLESS-*`, e.g. Sunshine).
  4. The old hand-written Samsung rules in `hyprland.lua` and `monitors.lua` are **kept on purpose**: the generated file only describes connected displays, so removing them would stop the Samsung being placed and its workspaces assigned when plugged in. They go once plug-in handling applies profiles.
  5. `hyprctl output remove` only works while the output is enabled.
- **Tested with a virtual display** (no real second screen was connected): mirror, un-mirror, scale, disable, re-enable, last-display guard, revert, 15 s auto-revert, and Keep (file written, temporary profiles removed). **Not yet tested** on the Samsung or a real projector.
- **Confirmation dialog (2026-10-24)**: the "Keep these display settings?" banner scrolled out of view inside Nexus, so it is now a centred overlay (`modules/displays/DisplayConfirm.qml`) with a dimmed backdrop, a translucent blurred card, a countdown ring, a one-line summary of what changed, Enter to keep and Esc to go back. It shows on the focused screen whether or not Nexus is open. Its blur comes from adding `caelestia-display-confirm` to the namespaces in `Colours.reloadHyprRules` (no Hyprland config edit). The scale menu now offers only scales Hyprland accepts for the display's resolution (Hyprland silently rounded e.g. 1.10 to 1.20).
- **Fixes after your first round of testing (2026-10-24)**:
  1. Dropdowns, switches and steppers on the Display page stopped following the real value after you used them (a selection replaces their binding), so Revert changed the screen but not what the page showed. They now use `Binding` objects; `StepperRow` got the same repair.
  2. The Nexus window now resizes and re-centres when the screen's size changes (Hyprland only reads a window's size at creation). The scale menu now lists the scales Hyprland truly accepts for the panel; on 1080p it cannot do 85% or 90% (it snaps both to 83%), so those appear as 83% and 94%.
  3. Reordering workspaces in the overview now renumbers the workspaces (`hl.dsp.workspace.change_id`, one batched request) instead of moving every window twice, which re-tiled each window and flooded the shell with events. Windows keep their layout. The old method remains as a fallback. (This lives in the overview files that are still uncommitted in the working tree, so it is not in the pushed branch yet.)
  4. `services/DockPins.qml` unpins apps that no longer have a desktop entry (it also looks up entries hidden from the launcher, and waits for the app list to settle).
  5. The QuickNote editor scrolls to keep the text cursor in view, so it can be used without the mouse.
- **Second round of fixes (2026-10-24)**:
  1. Rotation: the data path was already correct (selecting 90° applies transform 1, Keep saves it). The real problem was the interface after rotating: on a 1152×2048 portrait screen the Nexus window became 2551×1434, far wider than the screen and half off it. Nexus is now capped to fit the screen (`Nexus.qml`).
  2. The shared `Menu` is now scrollable with a capped height (340 px), opens upward when there is more room above, and scrolls the current choice into view. Measured with 13 items at the bottom of a small window: 632 px of content, shown at 340 px, opens upward.
  3. After a workspace reorder the bar's indicator kept the old dot lit: Hyprland does not announce a renumbering, so the shell's copy of each monitor's active workspace went stale. The overview now refreshes workspaces, then monitors, then windows, three times after a reorder. Checked over three consecutive swaps. (Same note: uncommitted overview files.)
  4. The display service now refreshes the real display state before the first change of a confirmation window, so a change made outside the shell (or a stale copy) can no longer be applied or "reverted" to the wrong values.
- **Plug-in chooser (2026-10-24)**: when a display is plugged in, the shell either applies the layout you saved for exactly this set of displays (matched by display description, ignoring virtual outputs, newest wins) and shows a toast, or opens a keyboard-driven chooser (`modules/displays/DisplayChooser.qml`): Extend, Mirror, Display only, Laptop only; arrows or Tab, 1-4, Enter, Esc. A chosen layout goes through the same Keep/Revert dialog, and Keep saves it, so the same displays are "known" next time. Displays already connected at shell start are not treated as new. `qs ipc call displays chooser` opens it by hand.
- **Unplug safety net**: if nothing physical is left on (for example "Display only" and the cable is pulled), the laptop panel is switched back on at its last scale and rotation. Found by testing: Hyprland adds a placeholder output named `FALLBACK` when the last display goes away, and the first version counted it as a working display.
- **Tested**: plug-in event to chooser, arrows and number keys, Esc, mirror through the chooser, the unplug safety net (twice), and the saved-layout matching with seven made-up cases. **Not tested** on a real second screen or projector.
- **Finished 2026-10-24**:
  - **Projector crop, cause found**: Hyprland's documentation says a mirror is not re-rendered for the second screen ("squishing and stretching will occur on aspect ratios that differ (e.g 16:9 and 16:10)"). The old Mirror preset set the projector to its *preferred* mode, usually 4:3 or 16:10, so the laptop's 16:9 picture was distorted. Mirroring now picks the mirrored display's highest-resolution mode with the same shape as the source (60 Hz preferred), and if none exists the confirmation dialog says the picture may look stretched. Tested with five made-up mode lists (not on a real projector).
  - **Per-display interface size**: an "Interface size" row (80, 85, 90, 100, 110, 125, 150%) per display, stored in that display's own `~/.config/caelestia/monitors/<name>/shell.json` (font, padding and spacing scales). It applies live and affects only that display; this also gives the 85% and 90% that Hyprland's own scale cannot.
  - **Delete a profile** from Nexus, with a two-step trash button (press twice within 3 seconds).
- **Still to do**: confirm all of this on a real second screen or projector; hide the old Samsung rules in `hyprland.lua` once profile switching has proven itself on real hardware.
- **Done when**: plugging into the Samsung and a 1366x768 or 1024x768 display gives an uncropped mirror, a correctly sized shell, and no workspaces or windows jumping around, all controlled from Nexus.

### `[ ]` 1.4 Small visible bugs

| Bug | Where | Fix |
|---|---|---|
| ~~Overview header shows "2 2"~~ (done 2026-10-24) | `modules/overview/components/WorkspaceCard.qml`: the header shows the workspace number in a badge and, next to it, the workspace *name*, which Hyprland sets to the number itself for numbered workspaces. The intended second slot is the name of the active window | The slot now shows the app of the window last used in that workspace ("Zen Browser", "foot"), a workspace's own name if it has one, `special:` stripped, or "Empty" |
| Text cut off: "Hyprland..." (dashboard user card), "Screen rec..." (sidebar recorder card) | dashboard and utilities cards | Fit the text, shorten the labels, or reflow the layout |
| Further glitches you spot | — | Add them to this table as they appear |

### `[x]` 1.5 "Doctor": a self-healing page in Nexus

**Status (2026-10-24)**: page done (Nexus > System > Doctor, `scripts/doctor.py`): 13 read-only checks; fixes for radios, duplicate bt-agent, portals, audio, polkit agent start, crash dismissal, and per-profile Forget/Keep for duplicate Wi-Fi profiles. **Watchdog (2026-10-25)**: `services/DoctorWatchdog.qml` runs `doctor.py check --watch` (11 quick checks, about 0.1 s of CPU at the lowest priority) every 2/5/15/30 minutes (default 5, first look after 90 s), pauses in game mode, and shows one notification per new problem (again only if it changes or comes back). The first run after a fresh start only announces real breakage. On/off and the interval are on the Doctor page. **Not done**: Bluetooth device reset.


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

### `[x]` 1.6 Nexus search (does nothing today)

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

### `[x]` 2.1 Density: make things smaller, tuned live

**Status (2026-10-24)**: done and tested by you. Nexus > **Look & feel** (one page for all of Track 2; glass, motion and fonts become sections of it). `services/Density.qml` pushes window gaps and border to Hyprland live and re-applies them after a config reload; game mode is respected. Presets set window spacing only (Comfortable = whatever `variables.lua` says, Compact, Dense). Interface size is the same per-display setting as Display > Interface size (one shared row component), so the two pages always agree. **Not done**: app-content scaling (GTK/Qt/Chromium text), which stays optional.


You want to tune this live rather than get a fixed number.

- **Shell**: the existing scale settings in `shell.json`: `appearance.font.scale`, `appearance.padding.scale`, `appearance.spacing.scale`, `appearance.rounding.scale`, plus the screen-border `thickness` and `rounding`.
- **Window chrome**: the Hyprland variables in `~/.config/hypr/variables.lua` (`windowGapsIn` / `windowGapsOut` / `workspaceGaps` / `singleWindowGapsOut`, `windowBorderSize`).
- **App content**:
  - GTK: `org.gnome.desktop.interface text-scaling-factor`
  - Qt: font size in qt6ct and qt5ct
  - Chromium and Electron (Chrome, Claude, WhatsApp, Obsidian, VS Code): `--force-device-scale-factor` or per-app zoom
- **Deliverable**: a "Density" section in Nexus with live sliders, plus three named presets: **Comfortable** (today's look), **Compact**, and **Dense**. You fine-tune from there.
- **Done when**: you have picked values you're happy with.

### `[x]` 2.2 Glass: examples you can compare

**Status (2026-10-24)**: done, you liked it. Nexus > Look & feel > Glass (`services/Glass.qml`): blur behind the overview, window opacity (default read from `variables.lua`), solid text windows, reset. Idea for later: keep only media regions solid in see-through windows, parked in `docs/IDEAS.md`.


You're happy with the glass today. These are examples only, each one switchable:

- **Overview background blur**: the overview's layer is named `caelestia-overview`, but the Hyprland blur rule only matches `caelestia-(drawers|quicknote)`, so its "Blurred Glassmorphic Backdrop" (`modules/overview/OverviewContent.qml`) isn't actually blurred. Option: add a blur rule plus a slightly stronger dim behind it.
- **Readability**: a version where only text-heavy app windows become opaque, compared against today's `windowOpacity = 0.92`.
- More examples get added here as we find them. Each is kept or dropped after you see it.

### `[x]` 2.3 Signature motion

**Status (2026-10-24)**: done in a lighter form (`services/Motion.qml`, Look & feel > Motion): one **Animation speed** for the shell and Hyprland (the shell's own `appearance.anim.durations.scale` plus Hyprland's speeds, read from `animations.lua` and changed live), and **Windows move like the shell** (Hyprland uses the shell's spatial and effects curves). The audit found that the "63 hard-coded durations" were mostly the About logo (34); the rest (keyboard layout popout 9, dock 7, overview carousel 6) ignore the speed setting and were left alone on purpose.


One consistent animation style for the whole shell: opening, closing, morphing, and moving between surfaces.

- Replace the roughly 63 hard-coded `duration:` values in QML with the shared animation tokens (`Tokens.anim.*`).
- Match Hyprland's window, workspace and layer curves (`~/.config/hypr/hyprland/animations.lua`) to the shell's curves, so windows and panels move the same way.
- Define the style in one place, so a future theme *could* override it without changing any theme folders (P5).
- **Done when**: side-by-side recordings show every surface moving the same way, and you prefer it.

### `[x]` 2.4 App font consistency (to show you, not to impose)

**Status (2026-10-24)**: done (`services/AppFonts.qml`, `scripts/app-fonts.py`, Look & feel > App fonts). A switch maps `sans-serif` and `monospace` to Adwaita Sans and JetBrains Mono through one owned fontconfig file, and sets the GTK fonts (the previous values are saved and restored when switched off). Extras: add your own font file (copied to `~/.local/share/fonts/caelestia/`, removable), a preview, and an option to use the same fonts in the shell (icons untouched; originals restored when off).


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

## 7. Track 4: Config in Nexus (added 2026-10-24)

**Idea (yours)**: in this kind of setup the config files play the role of the settings app, so Nexus should be able to change them, and eventually most config options should live in Nexus.

**Verdict**: yes, as an *override layer*, not by rewriting your files.

- **Facts**: `variables.lua` has 62 values, `keybinds.lua` about 123 bindings, `rules.lua` about 60 window and layer rules, plus small files for input, animations, gestures, autostart (about 870 lines in total). Nexus already edits `shell.json`, and Density already controls Hyprland live.
- **The risk**: if Nexus rewrites your hand-written Lua, edits collide, comments are lost, and a Nexus bug can break the whole session.
- **Rules**:
  1. Your files are never rewritten. Nexus keeps its choices in its own file; the shell applies them live and again after every reload (the Density model).
  2. Every setting has "reset to what the config says".
  3. Risky changes go through Keep/Revert (the 15 second undo already used for displays).
  4. Large files (keybinds, rules, autostart) are **read-only viewers first**, editing later and opt-in.
- **Order**:
  1. `variables.lua` values (gaps, opacity, blur, rounding, cursor): the Density model, extended.
  2. Input: keyboard repeat, touchpad, gestures.
  3. Animations (overlaps with 2.3 Signature motion).
  4. Keybinds: searchable viewer ("what does Super+X do?"), then rebinding with conflict detection.
  5. Window rules: viewer, then editor.
- **Done when**: you can change the settings you used to edit by hand from Nexus, undo any of it, and your own files are untouched.

---

## 8. Track 5: Make it installable by other people (added 2026-10-25)

**Why**: an earlier public release was hard for people to install. The shell is more than QML: a C++ plugin (about 2 min to build), `quickshell-git` and `caelestia-cli` from the AUR, about 20 other packages, a very new Hyprland (Lua config), and no starter Hyprland config.

**Decisions (2026-10-25)**
- **Targets**: Arch, CachyOS, EndeavourOS on **Hyprland only**. Niri (NiriOS) is a possible later track: it means rewriting the compositor-specific parts.
- **Routes**: an **AUR package** (main route) plus a **sturdier installer script** (backup route). Prebuilt plugin downloads are rejected: they break whenever Arch updates Qt. The existing Nix flake is a bonus to test.
- **Coexists with upstream Caelestia**: own install folder, own `op-caelestia` command, plugin in its own folder (the module names clash with upstream's `caelestia-shell` otherwise).
- **Releases**: `op-caelestia-shell` follows tested version tags, `op-caelestia-shell-git` follows `main`.
- **Dependencies**: keep depending on upstream `caelestia-cli`.
- **Layout**: a `dist/` folder in this repo holds the PKGBUILD(s), installer, starter configs and the restore tool.
- **Hyprland config handling**: never rewrite the user's config. The installer detects the format, shows the exact lines it will add, writes a timestamped **backup**, adds one include line to files we own, and `op-caelestia config restore` undoes it. The starter config (a clean, generic one built from the author's, with personal bits removed) is **optional** and generated in Lua and conf from one source. For `.conf` users an *optional* migration step runs an existing converter (hypr-migrate, hyprconf2lua or hyprmorph) on a copy, checks it with `Hyprland --verify-config` and keeps the original. No Lua-to-conf conversion (hand-written Lua can't be converted back). Hyprland has deprecated hyprlang since 0.55 and plans to drop it, so Lua is where things are going. Later: give Density, Glass, Motion and Displays a `hyprctl keyword` path so `.conf` users need no conversion.
- **Private files**: ROADMAP, COMPLETION, DISCOVERY, changes.md and docs/IDEAS.md come out of the public repo; copies are kept locally in a private folder.

**Phases**
1. **Clean the repo**: move the private files out, remove `.vscode` and similar, replace personal defaults (`~/padhai_in_linux/NOTE`, anything machine-specific), check the docs read well for strangers, rewrite README for the new install routes. Tracked build artefacts, if any, are removed too.
2. **Package**: release-mode plugin build, install to its own folder, `op-caelestia` launcher, PKGBUILD for tags and for `-git`, tested in a clean Arch container.
3. **Installer**: distro and Hyprland checks with clear messages, dry run, backup, restore, uninstall, optional starter config, optional migration.
4. **Starter config**: the generic Lua version first, the conf version generated from the same source.
5. **Test on clean systems** (Arch, CachyOS in a VM or container), then publish to the AUR, tag the first release, announce.
6. **Later**: `.conf` paths for the live features; Niri scoping.

**Done when**: someone on fresh CachyOS or Arch can run one command and get a working shell, and can undo any change the installer made.

---

## 9. Parked ideas

Suggested but not chosen this round. Kept here so they aren't lost.

- `[~]` Dynamic island: a live pill in the bar for timer, music, recording, downloads
- `[~]` Presentation-safe mode: automatic when mirroring or screen sharing; hides notifications
- `[~]` Study cockpit: Pomodoro + focus mode + lecture/PDF layout + per-subject progress
- `[~]` Quick Look / peek previews
- `[~]` Easy theme maker / theme inheritance (declined for now under P5)
- `[~]` "Living themes" with sounds and motion per theme. Interesting, but needs more thought about keeping themes light
- `[~]` Session snapshots, ActivityWatch timeline, universal search, smart notifications. Not reviewed yet

---

## 10. Next step

1. Review and push the plug-in chooser commit.
2. Switch `main` to this branch: tag the old `main` as `backup/old-main`, merge it in with `-s ours`, push as a fast-forward.
3. Then either a small round on Track 1 leftovers (1.4 small visible bugs, 1.5 "Doctor") or start Track 2 (density first, since the UI feels too big).
4. Track 3 (phone app) still waits for decisions D1-D7.
