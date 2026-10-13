# Upstream Update Completion Tracker (`COMPLETION.md`)

Use this document to track execution progress across all phases and subphases outlined in [`UPDATE_ROADMAP.md`](./UPDATE_ROADMAP.md).

**Status Legend:**
- `[ ] PENDING`: Not yet started
- `[/] IN PROGRESS`: Currently being executed or under review
- `[x] COMPLETED`: Executed, verified, and passing smoke tests

---

## Phase 0: Pre-Flight Safety & Baseline Preservation

- [ ] **Subphase 0.1: Checkpoint Local State & Backup Branches**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Snapshot all existing branches (`backup-custom-full-pre-sync`, `backup-custom-with-themes`, `custom`), save dirty work on `sync-upstream-v2.5` to a checkpoint branch, and establish a clean base.

- [ ] **Subphase 0.2: Extract Reference Diff of All Custom Modifications**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Export reference patch `git diff b1c9bbd0 custom` to preserve exact implementation details of all fork features.

---

## Phase 1: C++ Engine & Plugin Synchronization (`upstream/main` `a3a8fe59`)

- [ ] **Subphase 1.1: Fast-Forward Core Plugin Infrastructure to Upstream**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Synchronize `ringbuffer.hpp`, `audiocollector.cpp` (PipeWire quantum fix), `tokensattached` (per-monitor tokens), `rootnodes`, `circularbuffer`, `cutils`, and `filesystemmodel`.

- [ ] **Subphase 1.2: Port & Preserve Custom Config Nodes in the New Settings System**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Register `DockConfig` (`dockconfig.hpp`), `LockConfig` options (`showGif`, `pattern`), `DesktopClockPosition`, `UserPaths` dynamic theme asset getters in `rootnodes.hpp` and `CMakeLists.txt`.

- [ ] **Subphase 1.3: Port Universal Cross-Hardware GPU Monitoring**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Ensure `enums.hpp` contains `GpuType::Intel`, and `gpu.cpp`/`gpu.hpp` maintains Intel sysfs reading alongside AMD, NVIDIA, and Generic drivers.

- [ ] **Subphase 1.4: Update `CMakeLists.txt` Build Definitions**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain safe git describe fallbacks for `VERSION` and `GIT_REVISION`, enable `CMAKE_EXPORT_COMPILE_COMMANDS`. Full ninja build test passing.

---

## Phase 2: Services & Core Singletons Synchronization

- [ ] **Subphase 2.1: Synchronize `services/Audio.qml` with Upstream PipeWire Updates**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Preserve `getStreamName`, `getStreamIcon`, `isValidOutputSink` (unplugged HDMI & disconnected BT filter), and reactive Bluetooth device monitoring.

- [ ] **Subphase 2.2: Harmonize `services/Colours.qml` with Upstream**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Preserve `colourToHex` and `reloadHyprColours()` dynamic border/shadow synchronization for Lua and standard Hyprland configs.

- [ ] **Subphase 2.3: Harmonize `services/Wallpapers.qml`**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain fallback to active theme `defaultWall`.

- [ ] **Subphase 2.4: Permanent Removal & Decommission of Wi-Fi Hotspot Feature**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Permanently remove `Hotspot.qml`, `HotspotPage.qml`, `docs/hotspot.md`, hotspot quick toggles and status icons, and revert `Nmcli.qml` to clean upstream logic.

---

## Phase 3: Shell Entry, Drawers & Navigation

- [ ] **Subphase 3.1: Update `shell.qml` & `components/ScreenState.qml`**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain `dock`, `overview`, and `launcherPickCallback` properties on `ScreenState`; include `Overview {}` and `BtAgent` init in `shell.qml`.

- [ ] **Subphase 3.2: Synchronize `modules/drawers/ContentWindow.qml`**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Ingest upstream live toplevel window check (`activeWorkspace?.toplevels.values.length > 0`) for drag mask padding.

- [ ] **Subphase 3.3: Harmonize `modules/drawers/Interactions.qml`, `Panels.qml`, and `Regions.qml`**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain mutual exclusivity between Launcher and Dock hover/drag gestures, `dockHideTimer`, `Dock.Wrapper`, and input regions.

- [ ] **Subphase 3.4: Preserve Overview / Taskview Module**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain all 11 overview components in `modules/overview/`, `overview` shortcut in `Shortcuts.qml`, and `HorizontalFadeFlickable.qml`.

---

## Phase 4: Lock Screen Harmonization

- [ ] **Subphase 4.1: Integrate Upstream Session Buttons with Custom Lock Actions**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Synthesize upstream `enableSessionControls` with custom `LockActions.qml`, `PowerConfirm.qml`, and `showGif` toggle support.

- [ ] **Subphase 4.2: Combine Password Visibility Toggle with Pattern Grid Mode**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Integrate upstream password reveal button with custom `patternToggle` and `PatternGrid.qml` in `PasswordInput.qml` and `Center.qml`.

- [ ] **Subphase 4.3: Retain Weather and Media Lock Screen Integrations**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain `WeatherInfo.qml`, `BriefInfo.qml`, `Media.qml`, `Fetch.qml`, and `NotifDock.qml` styling.

---

## Phase 5: Bar, Dashboard & Launcher Integration

- [ ] **Subphase 5.1: Ingest Upstream Workspaces v2 into Bar**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Adopt upstream `LazyListView` workspace rendering, Material shape indicators, occupied animations, and per-monitor workspace settings while keeping `ActiveWindow.qml` and clean status icons.

- [ ] **Subphase 5.2: Preserve Per-Application Audio Popout**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain per-application volume sliders and stream routing in `modules/bar/popouts/AudioPopout.qml` with upstream translation support.

- [ ] **Subphase 5.3: Retain Theme Engine in Launcher**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Keep `ThemeManager.qml`, `ThemeItem.qml`, and theme filtering in `AppList.qml`.

---

## Phase 6: Nexus Settings & Module Suite Synchronization

- [ ] **Subphase 6.1: Synchronize `PageRegistry.qml` & `PageCompRegistry.qml`**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Register all fork pages (`DockPanel`, `OverviewPanel`, `OsdPanel`, `LockScreenPage`, `PowerIdlePage`, `ThemeSelect`, `DesktopBackground`, `BluetoothPairingDialog`) with Hotspot omitted.

- [ ] **Subphase 6.2: Retain UI Controls Enhancements**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Retain `disabled` property support in `StepperRow.qml`, `SliderRow.qml`, and `SelectRow.qml`.

- [ ] **Subphase 6.3: Harmonize Clock Format Settings**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Update settings bindings from `useTwelveHourClock` to upstream enum `clockFormat`.

---

## Phase 7: Assets, Scripts, Tooling & Documentation

- [ ] **Subphase 7.1: Verify Bundled Themes & Assets**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Verify all 7 themes (`Abstract_Purple`, `berserk`, `Deadpool`, `Gojo`, `LOTM`, `Pikachu`, `Shinchan`) and their assets exist in `assets/themes/`.

- [ ] **Subphase 7.2: Verify Standalone Daemons & Scripts**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Test `scripts/bt-agent.py`, `scripts/run-local-shell.sh`, `scripts/startup-shell.sh`.

- [ ] **Subphase 7.3: Maintain Custom Installer & Documentation Suite**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Verify `install.sh`, complete `docs/` suite (no hotspot.md), and `README.md`.

---

## Phase 8: Compilation, Integration Testing & Final Sign-Off

- [ ] **Subphase 8.1: Full C++ Plugin Build & Clean**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Execute `cmake -B build -G Ninja && cmake --build build` with 0 warnings/errors.

- [ ] **Subphase 8.2: QML Syntax & Import Verification**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Run QML linting / check scripts to ensure no undefined symbols or broken imports.

- [ ] **Subphase 8.3: Runtime Smoke Tests Checklist**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Execute comprehensive interactive testing (Theme engine, Dock, Overview, Lockscreen pattern & power confirm, Audio popout, Bluetooth pairing, GPU telemetry, Workspaces v2, verified complete Hotspot removal).

- [ ] **Subphase 8.4: Git Consolidation & Merge Finalization**
  - **Status**: `[ ] PENDING`
  - **Date Started**: 
  - **Date Completed**: 
  - **Notes**: Create clean git commit history, merge into desired branch, push to `origin`.

---

## Progress Summary
- **Total Phases**: 9 (0 to 8)
- **Total Subphases**: 25
- **Subphases Completed**: 0 / 25 (0%)
- **Target Branch**: `sync-upstream-latest`
- **Upstream Target Commit**: `caelestia-dots/shell@a3a8fe59`
