# Caelestia Shell Upstream Synchronization Roadmap

This roadmap outlines the complete, phased engineering plan to update this codebase from its current state to the bleeding-edge upstream **Caelestia Shell** (`caelestia-dots/shell` at `upstream/main` / commit `a3a8fe59`+) while **strictly preserving 100% of custom modifications and added features** (`op-caelestia-shell`).

---

## Executive Summary & Architecture Strategy

### Objective
Upgrade the core C++ plugin engine, QML modules, services, and tooling to the latest upstream release while keeping all custom extensions fully operational:
- **Zero Feature Loss**: All custom features (Dynamic Themes, Dock, Overview Taskview, Lock Screen Pattern & Actions, Audio Popout per-stream controls, Intel/AMD/NVIDIA GPU telemetry, Bluetooth Pairing Agent, Nexus custom pages, and Custom Installer) remain intact.
- **Decommissioned Features**: Wi-Fi Hotspot feature is permanently removed and cleaned up across all modules.
- **Upstream Innovations Ingested**: Ingest Workspaces v2 (`LazyListView`, Material shapes, gap markers), new C++ Config Architecture (static defaults, per-monitor tokens, scoped enums), PipeWire audio quantum & correctness fixes, i18n translation engine, lock session buttons, and drawer live-toplevel padding.
- **Harmonious Integration**: Reconcile overlapping modifications in C++ headers, lock screen components, audio services, and drawer interaction controllers cleanly without regressions.

---

## Phase Breakdown Matrix

| Phase | Title | Primary Objective |
| :--- | :--- | :--- |
| **Phase 0** | Pre-Flight & Baseline Preservation | Snapshot all working branches, create isolated sync branch, verify clean working tree |
| **Phase 1** | C++ Engine & Plugin Alignment | Update plugin to latest upstream `a3a8fe59`, integrate custom config nodes & GPU telemetry |
| **Phase 2** | Services & Core Singletons Sync | Merge upstream PipeWire & i18n changes with custom audio filtering, colours & remove Hotspot |
| **Phase 3** | Shell Entry, Drawers & Navigation | Integrate live toplevel padding with dock/launcher mutual exclusivity and overview |
| **Phase 4** | Lock Screen Harmonization | Synthesize upstream session buttons & password visibility with pattern grid & power confirm |
| **Phase 5** | Bar, Dashboard & Launcher Integration | Apply Workspaces v2, new clock options, and retain theme launcher & active window fixes |
| **Phase 6** | Nexus Settings & Module Suite Sync | Ensure custom pages (Dock, Overview, Themes, Lock) conform to new settings APIs |
| **Phase 7** | Assets, Scripts, Tooling & Docs | Validate bundled themes, BlueZ agent, install scripts, and docs (clean hotspot docs) |
| **Phase 8** | Compilation, Integration Testing & Final Sign-Off | Full ninja compilation, QML linting, live test run, and Git branch finalization |

---

## Detailed Phases and Subphases

### Phase 0: Pre-Flight Safety & Baseline Preservation

#### Subphase 0.1: Checkpoint Local State & Backup Branches
- **Goal**: Ensure no work is lost and multiple restorable checkpoints exist.
- **Files Involved**: Git refs (`refs/heads/*`).
- **Actions**:
  1. Verify existing backup branches: `backup-custom-full-pre-sync`, `backup-custom-with-themes`, and `custom`.
  2. Commit or stash any pending uncommitted work on `sync-upstream-v2.5` to a dedicated safety branch `checkpoint-sync-v2.5-work`.
  3. Create a fresh working branch `sync-upstream-latest` tracking `upstream/main` as the rebase/merge target.
- **Verification**: `git status` clean, all branches intact and verified with `git branch -v`.

#### Subphase 0.2: Extract Reference Diff of All Custom Modifications
- **Goal**: Generate precise diffs of all fork changes to guarantee no feature is overlooked.
- **Actions**:
  1. Generate patch/diff between upstream base `b1c9bbd0` and fork branch `custom`: `git diff b1c9bbd0 custom > /tmp/custom-features.patch`.
  2. Inventory all untracked and custom files (Theme assets, dock files, overview files, hotspot files, scripts).
- **Verification**: Manifest of custom files matches all 133 modified and added files.

---

### Phase 1: C++ Engine & Plugin Synchronization (`upstream/main` `a3a8fe59`)

#### Subphase 1.1: Fast-Forward Core Plugin Infrastructure to Upstream
- **Goal**: Adopt upstream's latest C++ architecture, bugfixes, and build system.
- **Files Involved**:
  - `plugin/include/util/ringbuffer.hpp` (New upstream lock-free ringbuffer)
  - `plugin/src/Caelestia/Services/audiocollector.cpp` & `audiocollector.hpp` (PipeWire quantum reduction fix `#2121`)
  - `plugin/src/Caelestia/Config/tokensattached.cpp` & `tokensattached.hpp` (Per-monitor tokens instance `#2123`)
  - `plugin/src/Caelestia/Config/rootnodes.cpp` & `rootnodes.hpp` (Upstream root node registry)
  - `plugin/src/Caelestia/circularbuffer.cpp` & `circularbuffer.hpp`
  - `plugin/src/Caelestia/cutils.cpp` (Image grab release `#2093`)
  - `plugin/src/Caelestia/Models/filesystemmodel.cpp` (Subdirectory scan fix `#2101`)
  - `plugin/src/Caelestia/Config/enums.hpp` (Fix lowercase enum export `#2139`)
- **Actions**:
  1. Synchronize C++ core files with `upstream/main`.
  2. Ensure `.editorconfig` formatting and clang-tidy standards are respected.

#### Subphase 1.2: Port & Preserve Custom Config Nodes in the New Settings System
- **Goal**: Ensure custom configurations are registered according to the new `settings::ObjectNode` static default pattern.
- **Files Involved**:
  - `plugin/src/Caelestia/Config/dockconfig.hpp`: Maintain `DockConfig` (`enabled`, `showOnHover`, `maxSlots`, `dragThreshold`, `pinnedApps`).
  - `plugin/src/Caelestia/Config/lockconfig.hpp`: Retain `showGif`, `enablePattern`, and `pattern`.
  - `plugin/src/Caelestia/Config/backgroundconfig.hpp`: Retain custom `DesktopClockPosition` (`left`, `top`, `right`, `bottom`) and `invertColors`.
  - `plugin/src/Caelestia/Config/userpaths.hpp`: Retain `themeName`, `themeAsset()` helpers, and dynamic Q_PROPERTIES (`sessionGif`, `mediaGif`, `lockGif`, `notifBg`, `defaultWall`).
  - `plugin/src/Caelestia/Config/rootnodes.hpp`: Ensure `CONFIG_SUBOBJECT(DockConfig, dock)` is declared.
  - `plugin/src/Caelestia/Config/CMakeLists.txt`: Ensure `dockconfig.hpp` is registered.
- **Verification**: Header syntax conforms with `CONFIG_NODE`, `CONFIG_PROPERTY`, `CONFIG_GLOBAL_PROPERTY`.

#### Subphase 1.3: Port Universal Cross-Hardware GPU Monitoring
- **Goal**: Preserve multi-vendor GPU monitoring (Intel i915/xe, AMD amdgpu, NVIDIA NVML/fallback, Generic).
- **Files Involved**:
  - `plugin/src/Caelestia/Config/enums.hpp`: Keep `Intel` in `GpuType` enum: `ENUM(GpuType, Auto, Nvidia, Intel, Generic, None)`.
  - `plugin/src/Caelestia/Services/gpu.cpp` & `gpu.hpp`: Retain sysfs frequency/load reader for Intel cards, graceful sysfs error recovery, and robust property notifications.
- **Verification**: Compilation succeeds without symbol collisions or enum export warnings.

#### Subphase 1.4: Update `CMakeLists.txt` Build Definitions
- **Goal**: Preserve build robustness and Git tag extraction fallbacks.
- **Files Involved**: `CMakeLists.txt`.
- **Actions**:
  - Retain `CMAKE_EXPORT_COMPILE_COMMANDS ON`.
  - Retain safe tag matching `v[0-9]*` and fallback `VERSION = "2.5.0"`, `GIT_REVISION = "unknown"`.
- **Verification**: `cmake -B build -G Ninja && cmake --build build` compiles with 0 errors.

---

### Phase 2: Services & Core Singletons Synchronization

#### Subphase 2.1: Synchronize `services/Audio.qml` with Upstream PipeWire Updates
- **Goal**: Keep upstream audio provider stability while preserving custom stream intelligence and sink filtering.
- **Files Involved**: `services/Audio.qml`.
- **Merge Details**:
  - Preserve `getStreamName(stream)`: Heuristic app name & media title cleaner (Zen Browser, Chromium, etc.).
  - Preserve `getStreamIcon(stream)`: Heuristic desktop entry icon lookup.
  - Preserve `isValidOutputSink(node)`: Filtering out phantom unplugged HDMI outputs and unbonded Bluetooth profiles.
  - Preserve reactive Bluetooth connections tracking (`Bluetooth.devices.onValuesChanged`).
  - Preserve per-stream volume/sink control hooks.
  - Ingest upstream audio node error handling and signal updates.

#### Subphase 2.2: Harmonize `services/Colours.qml` with Upstream
- **Goal**: Keep upstream Material color palette loading while preserving dynamic Hyprland border synchronization.
- **Files Involved**: `services/Colours.qml`.
- **Merge Details**:
  - Preserve `colourToHex(c)` and `reloadHyprColours()`.
  - Retain dynamic updates to Hyprland `general:col.active_border`, `general:col.inactive_border`, shadow color, group borders for both Lua and standard conf configs.
  - Trigger `reloadHyprColours()` on shell startup, Hypr config reload, and palette changes.

#### Subphase 2.3: Harmonize `services/Wallpapers.qml`
- **Goal**: Retain dynamic theme default wallpaper fallback.
- **Files Involved**: `services/Wallpapers.qml`.
- **Merge Details**:
  - Retain `fallback: Paths.absolutePath(GlobalConfig.paths.defaultWall)` instead of hardcoded webp.

#### Subphase 2.4: Permanent Removal & Decommission of Wi-Fi Hotspot Feature
- **Goal**: Completely remove all traces of the native Wi-Fi Hotspot feature and associated hooks from the codebase.
- **Files Removed/Cleaned**:
  - `services/Hotspot.qml`: Ensure permanently removed.
  - `modules/nexus/pages/network/HotspotPage.qml`: Ensure permanently removed.
  - `docs/hotspot.md`: Ensure permanently removed.
  - `modules/nexus/pages/NetworkPage.qml`: Ensure no Hotspot subpage navigation entry exists.
  - `modules/nexus/PageCompRegistry.qml`: Ensure no `HotspotPage` component is registered.
  - `modules/utilities/cards/Toggles.qml`: Ensure no Hotspot quick toggle exists.
  - `modules/bar/components/StatusIcons.qml`: Ensure no Hotspot status icon exists.
  - `modules/nexus/pages/panels/taskbar/BarStatusIcons.qml`: Ensure no Hotspot bar settings entry exists.
  - `plugin/src/Caelestia/Config/barconfig.hpp` & `utilitiesconfig.hpp`: Ensure no hotspot configuration properties exist.
  - `services/Nmcli.qml`: Retain clean upstream network logic without AP hotspot scan filtering.
  - `install.sh`: Ensure no `dnsmasq` package requirement exists.
- **Verification**: `git grep -i "hotspot"` returns zero results (excluding standard QML Drag `hotSpot` properties).

---

### Phase 3: Shell Entry, Drawers & Navigation

#### Subphase 3.1: Update `shell.qml` & `components/ScreenState.qml`
- **Goal**: Provide unified global screen state properties and shell root declarations.
- **Files Involved**:
  - `components/ScreenState.qml`:
    - Retain `dock`, `overview`, and `launcherPickCallback`.
    - Retain `onLauncherChanged: if (launcher) dock = false;`.
  - `shell.qml`:
    - Keep `Overview {}` component inclusion.
    - Keep `BtAgent` singleton initialization `Component.onCompleted: void(BtAgent.active)`.

#### Subphase 3.2: Synchronize `modules/drawers/ContentWindow.qml`
- **Goal**: Ingest upstream live toplevel drag mask padding fix while preserving dock drawer support.
- **Files Involved**: `modules/drawers/ContentWindow.qml`.
- **Merge Details**:
  - Adopt upstream `80c40a14`: Use `monitor?.activeWorkspace?.toplevels.values.length > 0` instead of deprecated IPC window count.

#### Subphase 3.3: Harmonize `modules/drawers/Interactions.qml`, `Panels.qml`, and `Regions.qml`
- **Goal**: Maintain mutual exclusivity between Launcher and Dock hover/drag gestures.
- **Files Involved**:
  - `modules/drawers/Interactions.qml`:
    - Retain `dockHideTimer`, `dockShortcutActive`.
    - Retain smart hover vs drag arbitration: when launcher uses hover, dock uses drag; when launcher uses drag, dock uses hover.
    - Retain `onDockChanged` handler.
  - `modules/drawers/Panels.qml`:
    - Retain `Dock.Wrapper { id: dock ... }`.
  - `modules/drawers/Regions.qml`:
    - Retain Dock touch/pointer input region with context menu height padding.

#### Subphase 3.4: Preserve Overview / Taskview Module
- **Goal**: Keep the comprehensive workspace overview intact.
- **Files Involved**:
  - Entire `modules/overview/` directory (11 QML components: `Overview.qml`, `OverviewContent.qml`, `OverviewState.qml`, `AllWindowsGrid.qml`, `GhostWorkspaceCard.qml`, `Header.qml`, `MiniWindow.qml`, `NavigationFooter.qml`, `SegmentedNav.qml`, `SpecialCarousel.qml`, `WorkspaceCard.qml`, `WorkspaceCarousel.qml`).
  - `modules/Shortcuts.qml`: Keep `overview` shortcut (`toggleOverview`).
  - `components/containers/HorizontalFadeFlickable.qml`.

---

### Phase 4: Lock Screen Harmonization

#### Subphase 4.1: Integrate Upstream Session Buttons with Custom Lock Actions
- **Goal**: Seamlessly combine upstream session controls with custom power confirm & action pill.
- **Files Involved**:
  - `modules/lock/Lock.qml`
  - `modules/lock/LockSurface.qml`
  - `modules/lock/Center.qml`
  - `modules/lock/center/LockActions.qml`
  - `modules/lock/PowerConfirm.qml`
- **Merge Details**:
  - Ingest upstream `enableSessionControls` toggle from `LockConfig`.
  - Preserve custom `LockActions.qml` (quick restart, suspend, shutdown buttons) with modal `PowerConfirm.qml` safety confirmation.
  - Preserve `showGif` toggle support and theme lock GIF rendering.

#### Subphase 4.2: Combine Password Visibility Toggle with Pattern Grid Mode
- **Goal**: Merge upstream password visibility toggle (`6d3e6a96`) with custom pattern unlock grid.
- **Files Involved**:
  - `modules/lock/center/PasswordInput.qml`
  - `modules/lock/center/PatternGrid.qml`
  - `modules/lock/Pam.qml`
- **Merge Details**:
  - Ingest upstream `showPassword` state layer and toggle icon.
  - Preserve `patternToggle` IconButton (`keyboard` vs `grid_view`).
  - When `patternMode` is active: hide password input field, show `PatternGrid`, route unlock pattern directly to PAM authentication.
  - Retain fallback to password input on failed attempts or manual toggle.

#### Subphase 4.3: Retain Weather and Media Lock Screen Integrations
- **Files Involved**:
  - `modules/lock/WeatherInfo.qml`, `modules/lock/weather/BriefInfo.qml`.
  - `modules/lock/Media.qml`, `modules/lock/Fetch.qml`, `modules/lock/NotifDock.qml`.
- **Merge Details**:
  - Retain custom styling, spacing, and theme GIF background alignments.

---

### Phase 5: Bar, Dashboard & Launcher Integration

#### Subphase 5.1: Ingest Upstream Workspaces v2 into Bar
- **Goal**: Adopt upstream high-performance Workspaces v2 while keeping custom bar components.
- **Files Involved**:
  - Upstream workspaces components: `LazyListView`, `MaterialShape` indicators, occupied animations, per-monitor options, and window filters.
  - Custom additions to retain:
    - `modules/bar/components/ActiveWindow.qml`: Keep title truncate and icon styling fixes.
    - `modules/bar/components/StatusIcons.qml`: Retain clean status icons (no hotspot icon).

#### Subphase 5.2: Preserve Per-Application Audio Popout
- **Goal**: Ensure the audio popout displays per-application volume sliders and stream routing.
- **Files Involved**: `modules/bar/popouts/AudioPopout.qml`.
- **Merge Details**:
  - Retain tabbed or separated views for Audio Outputs (Sinks), Inputs (Sources), and Applications (Streams).
  - Retain mute toggles, volume sliders, app icon bindings, and stream name formatting.
  - Ingest upstream label formatting and translation strings (`Tr.trCtx`).

#### Subphase 5.3: Retain Theme Engine in Launcher
- **Goal**: Allow users to browse and switch themes directly from the app launcher.
- **Files Involved**:
  - `modules/launcher/services/ThemeManager.qml`: Theme scanner, active theme setting, asset swapping.
  - `modules/launcher/items/ThemeItem.qml`: Theme card delegate with preview.
  - `modules/launcher/AppList.qml`: Theme section / filter integration.
  - `modules/launcher/services/Actions.qml`: Theme command triggers.

---

## Phase 6: Nexus Settings & Module Suite Synchronization

#### Subphase 6.1: Synchronize `PageRegistry.qml` & `PageCompRegistry.qml`
- **Goal**: Ensure all fork subpages are registered alongside upstream pages.
- **Custom Pages Registered**:
  - Panels: `DockPanel`, `OverviewPanel`, `OsdPanel`, `LauncherPanel`.
  - Lock Screen: `LockScreenPage`, `PatternRecordDialog`, `PowerIdlePage`.
  - Wallpaper & Style: `ThemeSelect`, `DesktopBackground`.
  - Bluetooth: `BluetoothPairingDialog`.
  - *(Note: Hotspot page explicitly omitted/removed).*
- **Verification**: Ingest upstream dropdown clipping fixes (`7bb3716a`) and language setter (`9112a959`).

#### Subphase 6.2: Retain UI Controls Enhancements
- **Goal**: Maintain enhanced settings rows.
- **Files Involved**:
  - `modules/nexus/common/StepperRow.qml`, `SliderRow.qml`, `SelectRow.qml`: Retain `property bool disabled: false` and visual opacity/input suppression.

#### Subphase 6.3: Harmonize Clock Format Settings
- **Goal**: Align with upstream refactor `useTwelveHourClock -> clockFormat` enum.
- **Files Involved**:
  - `modules/nexus/pages/PanelsPage.qml` / bar settings:
  - Migrate any references from boolean `useTwelveHourClock` to `Config.general.clockFormat` (12-hour, 24-hour).

---

### Phase 7: Assets, Scripts, Tooling & Documentation

#### Subphase 7.1: Verify Bundled Themes & Assets
- **Goal**: Ensure all 7 bundled themes remain in `assets/themes/`.
- **Themes**:
  1. `Abstract_Purple`
  2. `berserk`
  3. `Deadpool`
  4. `Gojo`
  5. `LOTM`
  6. `Pikachu`
  7. `Shinchan`
- **Files per Theme**: `wallpaper.jpg`, `lock.gif`, `media.gif`, `session.gif`, `notif.png`.

#### Subphase 7.2: Verify Standalone Daemons & Scripts
- **Goal**: Maintain python bluetooth pairing agent and shell launchers.
- **Files Involved**:
  - `scripts/bt-agent.py`: Executable permissions, python3 BlueZ D-Bus integration.
  - `scripts/run-local-shell.sh`: Standalone development runner with local plugin path.
  - `scripts/startup-shell.sh`: Session startup launcher.

#### Subphase 7.3: Maintain Custom Installer & Documentation Suite
- **Goal**: Keep automated installer and documentation up to date.
- **Files Involved**:
  - `install.sh`: Interactive installer with Arch/CachyOS package resolution and Hyprland autostart detection (no dnsmasq requirement).
  - `docs/`: `audio.md`, `configuration.md`, `dock.md`, `hardware-compatibility.md`, `installation.md`, `lockscreen.md`, `nexus.md`, `overview.md`, `themes.md` (no hotspot.md).
  - `README.md`: Branding and feature overview.

---

### Phase 8: Compilation, Integration Testing & Final Sign-Off

#### Subphase 8.1: Full C++ Plugin Build & Clean
- **Goal**: Ensure clean ninja build without warnings.
- **Command**: `cmake -B build -G Ninja && cmake --build build`.
- **Criteria**: Zero errors, all shared libraries and QML plugins generated in `build/` and `qml/`.

#### Subphase 8.2: QML Syntax & Import Verification
- **Goal**: Verify no missing singletons, broken import paths, or undefined identifiers.
- **Command**: Run QML validator / linter or test run with `quickshell --check` / local shell runner.

#### Subphase 8.3: Runtime Smoke Tests Checklist
- [ ] Theme switching via Launcher and Nexus changes wallpapers, GIFs, and Hyprland border colors.
- [ ] Dock appears on hover/drag, pins apps, and context menu functions properly.
- [ ] Overview (Taskview) opens via shortcut, displays all workspaces/windows, and allows drag/close.
- [ ] Lock screen displays pattern unlock, toggles between pattern and password, supports password visibility, and triggers power confirm modal.
- [ ] Audio popout lists individual application streams and controls their volume.
- [ ] Bluetooth pairing dialog prompts and authenticates successfully.
- [ ] GPU telemetry displays load/frequency for Intel/AMD/NVIDIA without errors.
- [ ] Upstream Workspaces v2 animations and indicator shapes render correctly.
- [ ] Wi-Fi Hotspot is completely removed with zero lingering references or errors.

#### Subphase 8.4: Git Consolidation & Merge Finalization
- **Goal**: Clean git state with descriptive commit history and upstream tag alignment.
- **Actions**:
  - Commit consolidated updates cleanly.
  - Fast-forward or merge to target branch.
  - Push to remote origin when ready.
