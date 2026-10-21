# Caelestia Shell Deep Codebase Diagnostic & Reliability Roadmap (`docs/diagnostic-roadmap.md`)

## Executive Summary & Diagnostic Charter

### Objective
This roadmap provides an exhaustive, multi-layered engineering plan to perform a **deep-level forensic analysis and reliability audit** of the entire Caelestia QuickShell codebase (`caelestia-underWork` / `op-caelestia-shell`). The goal is to discover, catalog, triage, and eradicate:
- **Compile-time and static defects**: Syntax errors, unhandled types, implicit narrowings, uninitialized variables, dangling references, missing imports, and broken translation extractions.
- **Runtime crashes and instabilities**: Null-pointer / undefined dereferences, unhandled exception aborts, infinite recursion, event-loop starvation, Wayland surface grab deadlocks, and process crashes on idle/wake transitions.
- **Concurrency, threading, and IPC flaws**: Race conditions in PipeWire collector ringbuffers, D-Bus asynchronous request timeouts, Hyprland socket event fragmentation, and D-Bus BlueZ agent communication hiccups.
- **Memory, resource, and descriptor leaks**: Unbounded buffer expansion, unreleased QSG geometry nodes, unclosed file descriptors in `/proc` and `/sys` polling, retained QML component loaders, and leaking timers.
- **Architectural and logical anti-patterns**: Broken mutual exclusivity between shell layers (e.g. Dock vs. Launcher vs. Overview vs. Lock Screen), improper declarative-to-imperative QML workflows, unvalidated user configurations, hardcoded constants, and inefficient polling.
- **Security vulnerabilities**: Cleartext password handling in QML memory, improper PAM conversation lifecycles, unquoted shell argument execution in terminal wrappers, and overly permissive file permissions.
- **Coding convention and styling regressions**: 700+ QML coding convention violations, 2000+ broken internationalization (`qsTr` vs `Tr.tr`) bindings, and M3 design token inconsistencies across displays.

---

## Defect Severity & Classification Model

Every finding identified during the diagnostic phases is categorized according to this strict rubric:

| Severity Level | Priority | Definition | Examples in Caelestia Shell |
| :--- | :--- | :--- | :--- |
| **P0: Blocker / Critical** | Immediate | Crash to desktop, segmentation fault, lock screen bypass, unhandled process abort, infinite loop freezing compositor/shell. | `AnimatedImage` infinite loop on idle lock; segfault in PipeWire `audiocollector.cpp` on device disconnect; lock screen failing to grab keyboard. |
| **P1: Major / High** | High | Primary feature broken, persistent background memory leak, IPC socket death without reconnection, incorrect hardware telemetry reading. | Overview drag-drop failing to move windows; GPU sysfs parser failing on dual-GPU laptops; BlueZ pairing agent hanging indefinitely. |
| **P2: Normal / Medium** | Moderate | Secondary feature malfunction, race condition on rapid input, edge-case failure, broken fallback paths, missing timeout handling. | Audio popout volume slider desyncing; calendar leap-year edge cases; weather API offline error rendering undefined. |
| **P3: Minor / Low** | Low | Cosmetic glitch, layout shift, inefficient redundant property re-evaluation, minor styling inconsistency, missing tooltip. | 1px border misalignment on fractional scaling; redundant signal emissions; minor font baseline discrepancy. |
| **P4: Code Smell / Lint** | Backlog | Violation of Qt/QML coding standards, dead code, deprecated API calls, missing type annotations, internationalization markup errors. | 717 QML convention order violations; 2152 `qsTr()` calls instead of `Tr.tr()`; missing `readonly` qualifiers on static properties. |

---

## Complete Phase Matrix

| Phase | Domain / Subsystem | Primary Focus | Subphases |
| :--- | :--- | :--- | :--- |
| **Phase 0** | **Automated Static Scans & Tooling Setup** | Set up compiler sanitizers, AST linters, `qmllint`, `clang-tidy`, translation checkers, and repo-wide baseline audits. | 0.1 - 0.5 |
| **Phase 1** | **Core C++ Plugin Engine & Telemetry** | Deep inspection of `plugin/src/Caelestia/`: PipeWire ringbuffer, GPU/CPU sysfs, QSG scene graph, settings engine, and caching. | 1.1 - 1.12 |
| **Phase 2** | **Core QML Services & Reactive State** | Audit all 19 singletons in `services/`: Audio, Hyprland IPC, Screens, Colours, Nmcli, Notifs, Players, Pomodoro, and BtAgent. | 2.1 - 2.11 |
| **Phase 3** | **Shell Architecture, Drawers & Windows** | Audit `shell.qml`, `ScreenState.qml`, and `modules/drawers/`: layer shell exclusive zones, gesture masks, and mutual exclusivity. | 3.1 - 3.4 |
| **Phase 4** | **Lock Screen & Security Subsystem** | Forensic audit of `modules/lock/`: PAM auth flow, password memory security, pattern grid algorithm, fail-closed grabs, and idle wake. | 4.1 - 4.6 |
| **Phase 5** | **Taskbar, Workspaces v2 & Status Tray** | Audit `modules/bar/`: Workspaces v2 material rendering, Audio/Network/BT popouts, SNI system tray, and multi-monitor scaling. | 5.1 - 5.6 |
| **Phase 6** | **Dashboard, Performance Hub & Media** | Audit `modules/dashboard/`: Pomodoro falling shapes physics, CAVA visualizer, synchronized LRC lyrics, and hardware telemetry cards. | 6.1 - 6.5 |
| **Phase 7** | **Custom Dock & Overview Taskview** | Audit `modules/dock/` and `modules/overview/`: live window thumbnail rendering, coordinate mapping, drag-and-drop window migration, and search. | 7.1 - 7.6 |
| **Phase 8** | **Application Launcher & Search Subsystem** | Audit `modules/launcher/`: fuzzy search engines (`fzf`, `fuzzysort`), Qalculate inline math parsing, and terminal execution security. | 8.1 - 8.5 |
| **Phase 9** | **Nexus Settings Center & Config Engine** | Audit `modules/nexus/`: navigation architecture, page registries, hardware setting writers, theme pickers, and quarantine recovery. | 9.1 - 9.5 |
| **Phase 10** | **Notifications, OSD, Utilities & Area Picker** | Audit `modules/notifications/`, `modules/osd/`, `modules/sidebar/`, `modules/utilities/`, and Wayland interactive `AreaPicker`. | 10.1 - 10.5 |
| **Phase 11** | **Design System, UI Components & Performance** | Audit `components/`: controls, containers, image loaders, breadcrumb file dialog, M3 token propagation, and animation frame drops. | 11.1 - 11.7 |
| **Phase 12** | **External Scripts, Daemons & Build System** | Audit `scripts/` (`bt-agent.py`), `install.sh`, `update.sh`, CMake build configurations, compiler flags, and Nix packages. | 12.1 - 12.5 |
| **Phase 13** | **Runtime Stress Testing & Fault Injection** | Live runtime fuzzing: display hotplugging, gesture spamming, sleep/wake cycles, memory profiling, and compositor crash recovery. | 13.1 - 13.5 |
| **Phase 14** | **Synthesis, Remediation Plan & Final Audit Report**| Triage defect manifest, root cause taxonomy, architectural debt quantification, and publish executive diagnostic report. | 14.1 - 14.4 |

---

## Detailed Phases and Subphases

### Phase 0: Automated Static Scans, Tooling Setup & Baseline Audits

#### Subphase 0.1: Native C++ Static Analysis Setup (`clang-tidy`, ASan, UBSan)
- **Scope**: Entire C++ codebase (`plugin/src/`, `plugin/include/`, `extras/`).
- **Files**: `.clang-tidy`, `.clang-format`, `CMakeLists.txt`, `plugin/CMakeLists.txt`.
- **Target Vulnerabilities**:
  - Memory mismanagement, raw pointer ownership issues, uninitialized class members, implicit sign/width conversions.
  - Absence of AddressSanitizer (`-fsanitize=address`) and UndefinedBehaviorSanitizer (`-fsanitize=undefined`) in debug compilation profiles.
  - Missing `-Wall -Wextra -Wpedantic` warnings or suppressed fatal diagnostics.
- **Methodology & Tooling**:
  - Run `clang-tidy -p build` against all translation units registered in `compile_commands.json`.
  - Configure a clean debug build with AddressSanitizer enabled to catch buffer overflows and memory corruption.
- **Acceptance Criteria**: Full machine-readable diagnostic log of all C++ static warnings categorized by check type.

#### Subphase 0.2: QML Automated Syntax & AST Verification (`qmllint`)
- **Scope**: All `.qml` files across `components/`, `modules/`, `services/`, and `utils/`.
- **Files**: All 180+ QML files in the repository.
- **Target Vulnerabilities**:
  - Unresolved imports, syntax parsing anomalies, missing type declarations on properties, broken component pragmas (`pragma ComponentBehavior: Bound`).
  - Signal-handler signature mismatches, unrecognized attached properties.
- **Methodology & Tooling**:
  - Construct a comprehensive `qmllint` invocation script providing appropriate `-I` search paths (`-I . -I build/plugin/quick`).
  - Parse `qmllint` exit codes and capture all syntax errors and type resolution failures.
- **Acceptance Criteria**: Complete audit report of all QML syntax errors and unresolvable symbol references.

#### Subphase 0.3: Internationalization & Translation String Extraction Audit
- **Scope**: All QML and C++ source files using string user-facing text.
- **Files**: `scripts/trs-check.py`, `plugin/src/Caelestia/I18n/*`, all `.qml` files.
- **Target Vulnerabilities**:
  - Use of unextracted `qsTr()` instead of Caelestia's `Tr.tr()` / `Tr.trCtx()` / `Tr.trN()`.
  - Placeholder numbering mismatches (e.g. `%2` without `%1`, missing `.arg()` parameters).
  - Translating dynamic concatenated strings instead of formatted strings with arguments.
- **Methodology & Tooling**:
  - Run `python3 scripts/trs-check.py --json` across the entire codebase.
  - Catalog the 2,152 logged violations into an actionable file-by-file spreadsheet.
- **Acceptance Criteria**: Exact line-by-line inventory of all broken translation strings and unauthorized `qsTr()` usages.

#### Subphase 0.4: Qt/QML Coding Conventions & Structural Formatting Scan
- **Scope**: Structural ordering of IDs, properties, signals, JS functions, bindings, children, and component definitions.
- **Files**: `scripts/qml-lint-conventions.py`, all `.qml` files.
- **Target Vulnerabilities**:
  - Out-of-order declarations (e.g. bindings declared before properties, functions declared after child objects).
  - Missing empty separator lines between architectural sections violating Qt 6 guidelines.
  - Unsorted import statements (more nested imports preceding less nested imports).
- **Methodology & Tooling**:
  - Run `python3 scripts/qml-lint-conventions.py --json`.
  - Classify the 717 reported violations by severity and component category.
- **Acceptance Criteria**: Clean categorization of code-style debt across fork modules vs upstream modules.

#### Subphase 0.5: Shell Scripts, Python Daemons & System Packaging Linting
- **Scope**: All bash scripts, python helper scripts, PAM definitions, and Nix derivations.
- **Files**: `install.sh`, `update.sh`, `scripts/bt-agent.py`, `scripts/startup-shell.sh`, `assets/wrap_term_launch.sh`, `flake.nix`.
- **Target Vulnerabilities**:
  - Unquoted variable expansions in shell scripts, missing `set -euo pipefail` safety flags, hazardous `rm -rf` paths.
  - Python 3.12+ / 3.14 deprecation warnings in `bt-agent.py`, unhandled D-Bus exceptions, missing type hints.
  - Insecure file permissions (e.g., executable bits on non-scripts or world-writable config files).
- **Methodology & Tooling**:
  - Run `shellcheck` on all `.sh` and `.bash` scripts.
  - Run `flake8` / `mypy` on `scripts/bt-agent.py` and `scripts/*.py`.
- **Acceptance Criteria**: Zero unhandled shellcheck warnings and clean static verification of all standalone scripts.

---

### Phase 1: Core C++ Plugin Engine & System Telemetry Diagnostics (`plugin/`)

#### Subphase 1.1: Thread Safety, Ringbuffers & Audio Pipeline
- **Scope**: PipeWire audio capture and stream monitoring.
- **Files**: `plugin/src/Caelestia/Services/audiocollector.cpp`, `audiocollector.hpp`, `plugin/include/util/ringbuffer.hpp`.
- **Target Vulnerabilities**:
  - Race conditions between PipeWire real-time audio callback thread and Qt main GUI thread.
  - Ringbuffer head/tail pointer tear, memory order relaxations causing corrupted audio sample reads.
  - Buffer underruns or overruns during PipeWire quantum switches (e.g. 64 samples vs 1024 samples).
  - Deadlocks during PipeWire loop lock acquisition when an audio sink is abruptly unplugged.
- **Methodology & Tooling**:
  - Static code inspection of `audiocollector.cpp` mutex locks and atomic operations.
  - ThreadSanitizer (`-fsanitize=thread`) execution under simulated PipeWire audio playback.
- **Acceptance Criteria**: Proved thread-safe audio sample processing with zero race conditions or audio sample drop freezes.

#### Subphase 1.2: Digital Signal Processing & Visualizer Math
- **Scope**: CAVA FFT spectrum analysis, beat tracking, and audio providers.
- **Files**: `plugin/src/Caelestia/Services/audioprovider.cpp`, `cavaprovider.cpp`, `beattracker.cpp`.
- **Target Vulnerabilities**:
  - Division by zero in normalization passes when audio is silent or sample rate is zero.
  - Memory leaks or excessive allocations inside high-frequency frame calculation loops (60-144 FPS).
  - Floating point overflows / NaNs propagating into QML properties causing scene graph crashes.
- **Methodology & Tooling**:
  - Mathematical boundary value analysis on FFT calculations with 0.0, NaN, and Inf inputs.
  - Heap allocation profiling inside `cava::calculate()` to ensure zero dynamic heap allocation per frame.
- **Acceptance Criteria**: Deterministic, zero-allocation DSP loop operating within a strict CPU budget (<1.5% CPU at 60 FPS).

#### Subphase 1.3: Multi-Vendor GPU Telemetry & Sysfs Driver Robustness
- **Scope**: GPU monitoring across Intel (i915/xe), AMD (amdgpu drm), NVIDIA (NVML/fallback), and Generic hwmon.
- **Files**: `plugin/src/Caelestia/Services/gpu.cpp`, `gpu.hpp`, `plugin/src/Caelestia/Config/enums.hpp`.
- **Target Vulnerabilities**:
  - Sysfs file read failures when GPU enters deep PCIe runtime sleep (`D3cold`), causing unhandled I/O exceptions or stalled pollers.
  - Crash or null pointer dereference on laptops with hybrid graphics (e.g. iGPU disabled in BIOS or discrete GPU powered off).
  - Division by zero in VRAM utilization calculations when total memory reports 0 bytes.
  - NVIDIA NVML dynamic symbol loading (`dlopen`/`dlsym`) failures or driver version mismatches.
- **Methodology & Tooling**:
  - Review all file path builders for `/sys/class/drm/card*` and `/sys/devices/pci*`.
  - Simulate missing sysfs nodes, unreadable files (permission denied), and zero-length responses.
- **Acceptance Criteria**: Bulletproof multi-GPU fallback hierarchy gracefully reporting `0` or `N/A` without console spam or crashes.

#### Subphase 1.4: System Metrics Hardware Monitors
- **Scope**: CPU, RAM, Disk, Storage, Network, and Hardware Sensors.
- **Files**: `cpu.cpp`, `memory.cpp`, `diskinfo.cpp`, `networkusage.cpp`, `storage.cpp`, `sensorslib.cpp`.
- **Target Vulnerabilities**:
  - File descriptor leaks from unclosed `std::ifstream` or `fopen()` handles in `/proc/stat` and `/proc/meminfo`.
  - String parsing buffer overflows when `/proc/net/dev` contains unexpected interface names (e.g. long WireGuard or container interfaces).
  - Blocking file system calls in `storage.cpp` when a network mount (NFS/CIFS) hangs.
  - `libsensors` memory leaks or thread contention during sensor chip iteration.
- **Methodology & Tooling**:
  - Audit all file-reading loops for RAII stream closures.
  - Stress-test network interface creation/deletion cycles with dummy virtual interfaces.
- **Acceptance Criteria**: Non-blocking, zero-leak telemetry polling guaranteed across all hardware states and mount types.

#### Subphase 1.5: Wayland & Hyprland IPC Engine & Socket Robustness
- **Scope**: Hyprland IPC socket listener, event stream processing, and device tracking.
- **Files**: `plugin/src/Caelestia/Services/hyprdevices.cpp`, `hyprextras.cpp`.
- **Target Vulnerabilities**:
  - Hyprland socket disconnects or crashes leaving dead sockets and zombie event loops.
  - Buffer fragmentation: handling partial JSON payloads or multiple concatenated events in a single socket read.
  - Dangling workspace or window pointers after rapid window close events.
- **Methodology & Tooling**:
  - Socket fuzzing: feed malformed, truncated, and rapid burst events into the Hyprland IPC parser.
  - Simulate compositor crash and verify graceful reconnection attempts without CPU spinning.
- **Acceptance Criteria**: Robust parser capable of handling fragmented streams, buffer overflows, and socket recovery.

#### Subphase 1.6: System Session & D-Bus Inhibitor Management
- **Scope**: Session state, sleep/wake events, systemd logind integration.
- **Files**: `plugin/src/Caelestia/Services/sessionmanager.cpp`, `sessionmanager.hpp`.
- **Target Vulnerabilities**:
  - Unreleased systemd sleep inhibitors preventing laptop suspend or draining battery.
  - D-Bus connection dropouts when `systemd-logind` restarts or times out.
  - Double-lock race condition when lid closes immediately following idle timeout.
- **Methodology & Tooling**:
  - Trace D-Bus method calls to `org.freedesktop.login1.Manager`.
  - Check file descriptor ownership for inhibitor lock file descriptors.
- **Acceptance Criteria**: Leak-free inhibitor lifecycle correctly signaling prepare-for-sleep before system suspend.

#### Subphase 1.7: Custom Config Nodes, Schema Validation & Serialization Engine
- **Scope**: Dynamic settings system, schema serialization, JSON parsing, and quarantine recovery.
- **Files**: `plugin/src/Caelestia/Settings/*`, `plugin/src/Caelestia/Config/rootnodes.cpp`, `dockconfig.hpp`, `lockconfig.hpp`, `userpaths.hpp`.
- **Target Vulnerabilities**:
  - Settings corruption if the system crashes during JSON write (atomic write / rename verification).
  - Quarantine failure: if user puts invalid type in `settings.json`, does the shell crash or safely isolate invalid keys?
  - Dynamic `UserPaths` getter functions returning invalid or unescaped file URLs.
  - Static object node default pointer lifecycles and dangling pointers on reload.
- **Methodology & Tooling**:
  - Fuzz configuration files with malformed JSON, wrong data types, and out-of-range numerical values.
  - Test concurrent config read/write operations with `changebatcher.cpp`.
- **Acceptance Criteria**: 100% resilient config engine with automated quarantine, atomic file writes, and valid property reflection in QML.

#### Subphase 1.8: Custom C++ QtQuick SceneGraph Components
- **Scope**: C++ visual items rendering directly to Qt Quick SceneGraph.
- **Files**: `lazylistview.cpp`, `animatedrepeater.cpp`, `visualiserbars.cpp`, `wavyline.cpp`, `sparklineitem.cpp`.
- **Target Vulnerabilities**:
  - QSGNode memory leaks: failing to delete old geometry nodes in `updatePaintNode()`.
  - OpenGL / Vulkan pipeline synchronization errors causing visual artifact flickering.
  - Index out-of-bounds in `LazyListView` during rapid model clearing or filtering.
- **Methodology & Tooling**:
  - Visual profiling using `QSG_VISUALIZE=overdraw` and `QSG_VISUALIZE=batches`.
  - Valgrind / Heaptrack audit of `updatePaintNode()` allocations across continuous scrolling.
- **Acceptance Criteria**: Zero heap allocations per frame in `updatePaintNode()`, zero node leaks, and flicker-free rendering.

#### Subphase 1.9: Shaders & Blob Rendering Pipeline
- **Scope**: GPU vertex and fragment shader execution for morphing blobs and shapes.
- **Files**: `plugin/src/Caelestia/Blobs/*`, `shaders/blob.frag`, `shaders/blob.vert`.
- **Target Vulnerabilities**:
  - Shader compilation failures on varying GPU drivers (Mesa radv, Intel iris, Nvidia proprietary).
  - Precision qualifiers (`mediump` vs `highp`) causing rendering artifacts on certain architectures.
  - Uniform buffer alignment mismatches between CPU and GPU.
- **Methodology & Tooling**:
  - Compile shaders across multiple GLSL targets and spirv-cross validators.
  - Test on Intel, AMD, and Nvidia graphics backends.
- **Acceptance Criteria**: Clean shader compilation with zero driver-specific warnings and validated uniform alignment.

#### Subphase 1.10: Image Processing, Color Extraction & Caching
- **Scope**: Wallpapers, cover art color analysis, and image caching.
- **Files**: `cachingimageprovider.cpp`, `imageanalyser.cpp`, `imagecacher.cpp`, `iutils.cpp`.
- **Target Vulnerabilities**:
  - Out-of-memory (OOM) abort when user selects an enormous 8K or 16K wallpaper for color extraction.
  - K-means clustering algorithm hanging the thread on degenerate or monochrome images.
  - Cache size unbounded growth consuming gigabytes of RAM over long uptime.
- **Methodology & Tooling**:
  - Benchmark color extraction on 8K TIFF/PNG images and zero-byte corrupted images.
  - Inspect cache eviction policy (`LRU` capacity limit enforcement).
- **Acceptance Criteria**: Bounded memory footprint, asynchronous non-blocking extraction, and graceful failure on corrupt images.

#### Subphase 1.11: XDG Models, App Database & Recursive Watchers
- **Scope**: Application desktop file discovery and filesystem models.
- **Files**: `plugin/src/Caelestia/Models/appdb.cpp`, `filesystemmodel.cpp`.
- **Target Vulnerabilities**:
  - Filesystem watcher file descriptor exhaustion (`inotify` limits) when watching deep directories.
  - Infinite recursion on directory symlink cycles.
  - Desktop entry parsing crashes on invalid UTF-8, non-standard key-value pairs, or missing Exec keys.
- **Methodology & Tooling**:
  - Test symlink loops (`ln -s . loop`) and deeply nested directories (100+ levels).
  - Parse corrupted and non-standard `.desktop` files.
- **Acceptance Criteria**: Symlink-safe traversal, bounded inotify descriptor usage, and robust desktop entry parser.

#### Subphase 1.12: Calculator Engine & Network Request Handlers
- **Scope**: Qalculate bindings, HTTP request wrapper, lyrics client, and toast notifications.
- **Files**: `qalculator.cpp`, `requests.cpp`, `lyrics.cpp`, `toaster.cpp`.
- **Target Vulnerabilities**:
  - Qalculate expression evaluation hangs (e.g. computing Ackermann numbers or massive factorial sequences).
  - Network request memory leaks: dangling `QNetworkReply` instances upon network disconnect.
  - Missing SSL error handling or certificate verification crashes.
- **Methodology & Tooling**:
  - Stress Qalculate engine with computational bombs and malformed syntax.
  - Simulate HTTP 4xx, 5xx, timeouts, and dropped connections in `requests.cpp`.
- **Acceptance Criteria**: Enforced calculation timeout limits (<150ms), leak-free network replies, and structured error responses.

---

### Phase 2: Core QML Services & Global Reactive State Machines (`services/`)

#### Subphase 2.1: Audio Management & Device Switching Architecture
- **Scope**: PipeWire audio routing, stream volume tracking, and device filters.
- **Files**: `services/Audio.qml`.
- **Target Vulnerabilities**:
  - Null reference errors when `sink`, `source`, or `stream` is suddenly disconnected (`sink?.audio?.volume`).
  - Filtering logic in `isValidOutputSink`: ensure disconnected Bluetooth or phantom HDMI ports do not block audio output.
  - Infinite binding loops during volume synchronization between hardware and UI sliders.
- **Methodology & Tooling**:
  - Trace property change events while plugging and unplugging virtual audio sinks via `pactl load-module`.
  - Audit reactive bindings for bidirectional cyclical assignments.
- **Acceptance Criteria**: Zero binding loops, zero null-pointer crashes on device disconnection, and accurate filtering of invalid sinks.

#### Subphase 2.2: Hyprland Window & Workspace Event Synchronization
- **Scope**: Hyprland IPC bridge, active window title tracking, workspace state mapping.
- **Files**: `services/Hypr.qml`.
- **Target Vulnerabilities**:
  - Race conditions between rapid workspace switches and window focus events.
  - Special workspace ID handling (negative IDs vs named special workspaces).
  - Desynchronization of active window title when switching to empty workspaces or full-screen windows.
- **Methodology & Tooling**:
  - Rapidly switch workspaces via script (`hyprctl dispatch workspace`) while monitoring `Hypr.qml` signals.
  - Verify state consistency across multi-monitor setups.
- **Acceptance Criteria**: Accurate window and workspace tracking under rapid switching with zero stale property values.

#### Subphase 2.3: Multi-Monitor Geometry & Scaling Calculations
- **Scope**: Multi-screen detection, DPI scaling, and primary monitor resolution changes.
- **Files**: `services/Screens.qml`.
- **Target Vulnerabilities**:
  - Division by zero or NaN coordinates when a monitor is connected with an unconfigured resolution or scale.
  - Crashing during monitor hotplug/unplug events when accessing `Quickshell.screens` array indices.
  - Primary monitor fallback logic when no monitor is explicitly designated primary.
- **Methodology & Tooling**:
  - Trigger simulated display addition and removal (`hyprctl keyword monitor ...`).
  - Inspect QML error logs for out-of-bounds screen array indexing.
- **Acceptance Criteria**: Clean screen geometry updates, dynamic adapter re-registration, and error-free multi-monitor operation.

#### Subphase 2.4: Dynamic Color Engine & Hyprland Integration
- **Scope**: M3 color extraction, palette generation, and Hyprland border/shadow synchronization.
- **Files**: `services/Colours.qml`.
- **Target Vulnerabilities**:
  - Hex color conversion errors producing malformed color codes (e.g. missing `#` or 7-character strings).
  - Hyprland configuration rewriting race conditions: file lock collisions when updating borders/shadows.
  - Contrast calculation errors rendering dark text on dark backgrounds under atypical wallpaper palettes.
- **Methodology & Tooling**:
  - Feed extreme wallpapers (pure white, pure black, neon gradients) into `Colours.qml`.
  - Validate generated Hyprland color commands and contrast ratios against WCAG AA standards.
- **Acceptance Criteria**: WCAG AA compliant contrast across all UI roles and atomic, error-free Hyprland color synchronization.

#### Subphase 2.5: Network Management & Credential Handling
- **Scope**: NetworkManager CLI wrapper, Wi-Fi scanning, and VPN connection tracking.
- **Files**: `services/Nmcli.qml`, `services/VPN.qml`, `utils/NetworkConnection.qml`.
- **Target Vulnerabilities**:
  - Command injection vulnerability: Wi-Fi SSIDs containing quotes, backticks, or special characters.
  - Cleartext password leakage in process argument logs when connecting to WPA networks.
  - Unhandled nmcli output format changes across NetworkManager versions.
- **Methodology & Tooling**:
  - Test Wi-Fi network names containing quotes (`"Test's Wi-Fi; rm -rf /"`).
  - Review all process invocations to ensure argument arrays are used rather than raw string concatenation.
- **Acceptance Criteria**: Safe parameterization of all shell/process commands and complete credential isolation from command line logs.

#### Subphase 2.6: Notification Server Daemon & Expiration Engine
- **Scope**: FreeDesktop notification server implementation, actions, and history.
- **Files**: `services/Notifs.qml`, `services/NotifData.qml`.
- **Target Vulnerabilities**:
  - Memory leak during notification storms (thousands of notifications spawned in minutes).
  - Timer expiration leaks: retained timers for dismissed or replaced notifications.
  - Malformed notification body HTML/markup causing text rendering engine crashes or script execution.
- **Methodology & Tooling**:
  - Stress-test with `notify-send` bursts (100 notifications/sec).
  - Inject rich markup (`<b>`, `<a>`, `<img src="...">`, unclosed tags) into notification bodies.
- **Acceptance Criteria**: Bounded memory buffer (max notification history limit), leak-free timer teardown, and safe text sanitization.

#### Subphase 2.7: Media Player MPRIS Coordination
- **Scope**: MPRIS D-Bus player discovery, multi-player playback arbitration, track metadata.
- **Files**: `services/Players.qml`.
- **Target Vulnerabilities**:
  - Polling timer drift or CPU spinning when tracking track position.
  - Rapid track switching causing out-of-order album art loading or stale metadata display.
  - Priority inversion: choosing a paused player over an actively playing player.
- **Methodology & Tooling**:
  - Test with multiple concurrent players (Spotify, Chromium, MPV, VLC).
  - Verify player switching, seek bar scrubbing, and volume control responsiveness.
- **Acceptance Criteria**: Smooth position interpolation, correct active player prioritization, and rapid metadata synchronization.

#### Subphase 2.8: Pomodoro Timer Logic & State Machine
- **Scope**: Pomodoro workflow (Work, Short Break, Long Break, Cycle Count), notifications, audio chimes.
- **Files**: `services/Pomodoro.qml`.
- **Target Vulnerabilities**:
  - State machine transition glitches (e.g. failing to transition from break back to work).
  - Time calculation drift when the system is suspended or under heavy CPU load.
  - Audio chime trigger failures when sound files are missing or PipeWire is busy.
- **Methodology & Tooling**:
  - Fast-forward timer state transitions and verify cycle counter progression.
  - Test suspend/resume recovery to ensure elapsed time is accurately accounted for.
- **Acceptance Criteria**: Deterministic state transitions, wall-clock synchronized time tracking, and reliable completion alerts.

#### Subphase 2.9: Screen Recorder Orchestration
- **Scope**: Video recording process spawning (`wf-recorder` / `wl-screenrec`), audio capture, and saving.
- **Files**: `services/Recorder.qml`.
- **Target Vulnerabilities**:
  - Zombie recording processes if the shell crashes or is restarted during an active recording.
  - File overwrite collisions: recording saving to an existing filename.
  - Audio sync drift between PipeWire audio recording and Wayland video capture.
- **Methodology & Tooling**:
  - Test start, pause, resume, and stop sequences.
  - Abruptly kill the shell process during active recording and verify process tree cleanup.
- **Acceptance Criteria**: Clean process termination (`SIGINT` graceful shutdown), collision-free unique file naming, and zero zombie processes.

#### Subphase 2.10: Weather API Client & Offline Resilience
- **Scope**: Weather data fetching (Open-Meteo / wttr.in), JSON parsing, geolocation, forecast caching.
- **Files**: `services/Weather.qml`.
- **Target Vulnerabilities**:
  - Shell freeze or unhandled rejection when network is offline or DNS lookup fails.
  - Weather JSON schema updates breaking property bindings (e.g. `weatherData.hourly.temperature_2m[0]` undefined).
  - Stale cache rendering without notifying user of offline status.
- **Methodology & Tooling**:
  - Simulate offline network, high latency (5000ms), and malformed HTTP 200 responses with empty JSON bodies.
  - Audit fallback properties and error status flags.
- **Acceptance Criteria**: Graceful offline degradation, clear error state reflection in UI, and zero property binding errors.

#### Subphase 2.11: Time, Idle Inhibition, GameMode & System Singletons
- **Scope**: Supporting system services.
- **Files**: `Time.qml`, `IdleInhibitor.qml`, `GameMode.qml`, `Brightness.qml`, `Wallpapers.qml`, `BtAgent.qml`, `ShellState.qml`.
- **Target Vulnerabilities**:
  - `Brightness.qml`: permission errors reading sysfs backlight or missing `brightnessctl` binary.
  - `Time.qml`: timezone change handling, daylight saving time shifts, 12h/24h toggle reactivity.
  - `BtAgent.qml`: initialization order in `shell.qml` (`Component.onCompleted: void(BtAgent.active)`).
  - `IdleInhibitor.qml`: Wayland idle inhibitor protocol leaks leaving screen permanently awake.
- **Methodology & Tooling**:
  - Toggle GameMode, adjust brightness without hardware backlight (external monitors), and test timezone shifts.
  - Audit singleton initialization order and circular dependency graphs.
- **Acceptance Criteria**: Independent, self-healing singletons resilient to hardware variations and configuration changes.

---

### Phase 3: Shell Architecture, Navigation & Window Drawers (`shell.qml`, `modules/drawers/`, `components/ScreenState.qml`)

#### Subphase 3.1: Root Shell Initialization, Lifecycle & Error Traps
- **Scope**: Root shell entry point, environment variables, singleton bootstrapping.
- **Files**: `shell.qml`, `modules/ServiceLoader.qml`, `modules/GSFLoader.qml`.
- **Target Vulnerabilities**:
  - Premature property access during component creation before singletons are initialized.
  - Environment variable overrides (`QS_DROP_EXPENSIVE_FONTS`, `QSG_RENDER_LOOP`) conflicting with GPU drivers.
  - Font loading race conditions: Google Sans Flex variable font instantiation timing.
- **Methodology & Tooling**:
  - Review startup logs with `QS_DEBUG=1` and `QT_LOGGING_RULES="*.debug=true"`.
  - Profile startup latency and component instantiation sequence.
- **Acceptance Criteria**: Clean startup with zero console warnings, zero binding breaks during load, and instant UI readiness.

#### Subphase 3.2: Screen State Coordinator & Mutual Exclusivity Rules
- **Scope**: Multi-panel state management, focus coordination, mutual exclusivity.
- **Files**: `components/ScreenState.qml`.
- **Target Vulnerabilities**:
  - Mutual exclusivity conflicts: opening launcher while dock is visible, opening overview while lock screen is active.
  - Focus trapping: losing keyboard focus when closing one drawer while another is partially open.
  - Per-screen state desynchronization on multi-monitor configurations (e.g. overview opening on wrong screen).
- **Methodology & Tooling**:
  - Matrix test all panel transitions: Dock <-> Launcher, Launcher <-> Overview, Overview <-> Dashboard, Lock <-> All.
  - Verify keyboard focus always returns to active window or default panel.
- **Acceptance Criteria**: Strict mutual exclusivity enforced across all panels with zero focus deadlocks.

#### Subphase 3.3: Drawer Sliding Window, Geometry Masks & Layer Shell Integration
- **Scope**: Wayland layer shell surface anchoring, exclusive zones, sliding animations.
- **Files**: `modules/drawers/Drawers.qml`, `ContentWindow.qml`, `Panels.qml`.
- **Target Vulnerabilities**:
  - Incorrect layer shell exclusive zone reservations pushing desktop windows off-screen.
  - Live toplevel window padding calculations (`activeWorkspace?.toplevels.values.length > 0`) lagging behind window open/close.
  - Visual clipping or shadow cutoff on sliding drawer animations.
- **Methodology & Tooling**:
  - Verify layer shell surfaces using `hyprctl layers`.
  - Test drawer sliding under 60Hz, 120Hz, and 144Hz refresh rates.
- **Acceptance Criteria**: Pixel-perfect layer shell anchoring, dynamic exclusive zones, and fluid drawer animations without frame drops.

#### Subphase 3.4: Touch & Mouse Gesture Interactions, Thresholds & Deadlocks
- **Scope**: Edge drag gestures, hover zones, input pass-through regions.
- **Files**: `modules/drawers/Interactions.qml`, `Regions.qml`, `Exclusions.qml`.
- **Target Vulnerabilities**:
  - Mouse hover dead zones blocking clicks to underlying desktop applications.
  - Touchpad swipe gesture thresholds triggering unintended panel openings during gaming or web browsing.
  - Region mask calculation errors allowing clicks to pass through active modal windows.
- **Methodology & Tooling**:
  - Verify input mask bounding boxes with debug visual overlays.
  - Test boundary click events across full screen edges and corners.
- **Acceptance Criteria**: Zero interference with underlying windows when panels are closed, and 100% reliable edge activation when gestures occur.

---

### Phase 4: Lock Screen & Security Subsystem Deep Audit (`modules/lock/`, PAM, Scripts)

#### Subphase 4.1: PAM Authentication Workflow & State Engine
- **Scope**: Pluggable Authentication Modules (PAM) integration, password/fingerprint/face auth.
- **Files**: `modules/lock/Pam.qml`, `modules/lock/Pam.cpp` (if applicable), `assets/pam.d/*`.
- **Target Vulnerabilities**:
  - Authentication thread deadlocks during PAM conversation callbacks.
  - Incomplete reset after failed authentication attempts locking out the user or entering invalid state.
  - Unhandled multi-factor authentication (e.g. fingerprint accepted while password field is dirty).
- **Methodology & Tooling**:
  - Simulate incorrect passwords, PAM timeouts, fingerprint reader disconnects, and rapid repeated submissions.
  - Verify PAM session open/close calls in system journal (`journalctl -u systemd-logind`).
- **Acceptance Criteria**: Flawless authentication state machine, proper PAM conversation teardown, and clear user error feedback.

#### Subphase 4.2: Password Security, Memory Zeroing & Cleartext Exposure
- **Scope**: Credential handling in memory, input fields, and clipboard security.
- **Files**: `modules/lock/center/PasswordInput.qml`, `InputField.qml`.
- **Target Vulnerabilities**:
  - Passwords stored in standard immutable `QString` or JS strings without explicit zero-memory wipes (`explicit_bzero`).
  - Passwords accidentally copied to Wayland clipboard or exposed in memory dumps/swap.
  - Cleartext password visibility toggles exposing sensitive credentials to shoulder surfers without automatic timeout.
- **Methodology & Tooling**:
  - Inspect process memory with GDB / core dumps after typing test passwords to detect cleartext string remnants.
  - Verify clipboard managers cannot intercept text entered into password inputs.
- **Acceptance Criteria**: Zero cleartext password persistence in memory heap dumps and complete clipboard isolation.

#### Subphase 4.3: Pattern Grid Gesture Recognition & Fallback Paths
- **Scope**: 9-dot pattern unlock grid, gesture recording, and path validation.
- **Files**: `modules/lock/center/PatternGrid.qml`.
- **Target Vulnerabilities**:
  - Pattern coordinate calculation errors under fractional display scaling (e.g. 1.25x, 1.5x).
  - Gesture recording race conditions: rapid touch/drag skipping intermediate dots.
  - Lockout scenario: user forgets pattern with no accessible fallback button to return to password auth.
- **Methodology & Tooling**:
  - Test pattern input across varying display scales and high-DPI monitors.
  - Test edge gesture vectors and verify immediate fallback toggle to standard PAM password entry.
- **Acceptance Criteria**: Scale-independent hit-box detection, robust dot path interpolation, and seamless fallback to password auth.

#### Subphase 4.4: Surface Locking, Wayland Grabs & Fail-Closed Guarantees
- **Scope**: Lock screen surface security, keyboard/pointer grabs, crash resilience.
- **Files**: `modules/lock/Lock.qml`, `LockSurface.qml`.
- **Target Vulnerabilities**:
  - Fail-Open vulnerability: if lock screen QML component throws an unhandled error, does the shell ungrab inputs or expose desktop?
  - Multi-monitor coverage: unplugging or plugging a monitor while locked leaving an uncovered desktop surface.
  - Global shortcut passthrough: audio keys or screenshot shortcuts leaking actions while locked.
- **Methodology & Tooling**:
  - Inject intentional QML exceptions into `LockSurface.qml` and verify the screen remains locked (fail-closed).
  - Hotplug secondary displays while in locked state.
- **Acceptance Criteria**: Absolute fail-closed security guarantee, universal multi-monitor lock surface coverage, and strict shortcut suppression.

#### Subphase 4.5: Power Confirmation, Session Teardown & Lock Media
- **Scope**: Shutdown/Reboot confirmation modal, lock screen media controls, notification dock.
- **Files**: `PowerConfirm.qml`, `LockActions.qml`, `Media.qml`, `NotifDock.qml`, `WeatherInfo.qml`.
- **Target Vulnerabilities**:
  - Power action execution without confirmation when triggered accidentally.
  - Sensitive notification contents leaking onto lock screen when privacy settings require redaction.
  - Media player controls remaining interactive even when unauthorized users are at the lock screen.
- **Methodology & Tooling**:
  - Test power dialog cancel/confirm mechanics.
  - Verify notification privacy redaction settings on locked surfaces.
- **Acceptance Criteria**: Intentional confirmation required for power actions and configurable privacy protection for notifications.

#### Subphase 4.6: Idle Timeout Synchronization & Sleep/Resume Handlers
- **Scope**: Idle monitoring, auto-lock timing, suspend/resume synchronization.
- **Files**: `modules/IdleMonitors.qml`, `services/ShellState.qml`.
- **Target Vulnerabilities**:
  - Regression check: verify `AnimatedImage` infinite recursion crash on idle lock does not reoccur.
  - Race condition on wake from suspend: screen displaying unlocked desktop for a fraction of a second before lock surface appears.
  - Sleep inhibitor conflicts preventing monitor power-saving (`dpms off`).
- **Methodology & Tooling**:
  - Simulate suspend and resume cycles via `systemctl suspend`.
  - Capture high-speed screen output on wake to ensure zero desktop frame leakage.
- **Acceptance Criteria**: Immediate lock surface presentation prior to display power-on with zero frame leakage or image recursion crashes.

---

### Phase 5: Taskbar, Workspaces v2 & Status Tray Architecture (`modules/bar/`)

#### Subphase 5.1: Taskbar Shell Window, Multi-Monitor Adaptation & Anchoring
- **Scope**: Main bar window, layer shell margins, anchor alignments.
- **Files**: `modules/bar/Bar.qml`, `BarWrapper.qml`.
- **Target Vulnerabilities**:
  - Anchor margin conflicts when taskbar position is set to Top vs Bottom vs Left vs Right.
  - Bar overlapping with full-screen windows or failing to reserve struts.
  - Per-monitor configuration overrides (e.g. bar enabled on monitor 1, disabled on monitor 2) not respected.
- **Methodology & Tooling**:
  - Test bar on multi-monitor configurations with mismatched aspect ratios (16:9, 21:9, 16:10).
  - Validate exclusive zone values via `hyprctl layers`.
- **Acceptance Criteria**: Clean geometry reservation, flexible multi-monitor placement, and seamless resolution adaptation.

#### Subphase 5.2: Workspaces v2 Rendering, Material Shapes & Event Handling
- **Scope**: Workspace indicator list, active indicator animations, gap markers, special workspaces.
- **Files**: `modules/bar/components/workspaces/*`.
- **Target Vulnerabilities**:
  - Material 3 shape deformation during rapid workspace switching animations.
  - Gap markers rendering in incorrect order when workspace IDs are non-sequential.
  - Mouse wheel scroll direction inverted or scrolling past maximum workspace count.
  - Special workspace indicator failing to update when scratchpad windows are toggled.
- **Methodology & Tooling**:
  - Create and destroy arbitrary workspace IDs (e.g. 1, 5, 8, 99) and monitor rendering stability.
  - Test fast scroll wheel navigation through workspaces.
- **Acceptance Criteria**: Flawless M3 shape transitions, correct gap marker alignment, and smooth scroll navigation.

#### Subphase 5.3: Audio Popout & Per-Application Stream Volume Controls
- **Scope**: Audio popout window, output sink selector, per-app stream sliders.
- **Files**: `modules/bar/popouts/AudioPopout.qml`.
- **Target Vulnerabilities**:
  - Volume slider jumps or nonlinear scaling when adjusting volume.
  - Application stream icons failing to load or showing broken fallback graphics.
  - Bluetooth output device profile switcher failing to reflect Handsfree vs A2DP sink modes.
- **Methodology & Tooling**:
  - Launch multiple audio streams (browser, media player, games) and adjust volumes concurrently.
  - Verify stream mute toggles and sink re-routing responsiveness.
- **Acceptance Criteria**: Smooth logarithmic/linear volume curves, instantaneous stream re-routing, and crisp icon rendering.

#### Subphase 5.4: Network, Bluetooth & Wireless Credential Popouts
- **Scope**: Wi-Fi network selector, password dialog, Bluetooth device manager.
- **Files**: `modules/bar/popouts/Network.qml`, `Bluetooth.qml`, `WirelessPassword.qml`.
- **Target Vulnerabilities**:
  - Wireless password dialog keyboard grab failing or letting keystrokes leak to background apps.
  - Bluetooth device list failing to refresh when new devices enter pairing mode.
  - Connection spinner spinning indefinitely on failed Wi-Fi handshake.
- **Methodology & Tooling**:
  - Test connection attempts with incorrect WPA keys and verify error prompt dismissal.
  - Pair and unpair Bluetooth peripherals while popout is open.
- **Acceptance Criteria**: Secure modal password input, accurate connection error notifications, and live Bluetooth device list updates.

#### Subphase 5.5: System Tray (SNI) & DBusMenu Protocol Implementation
- **Scope**: StatusNotifierItem tray icons, DBusMenu context menus, tray item activations.
- **Files**: `modules/bar/components/Tray.qml`, `TrayItem.qml`, `TrayMenu.qml`.
- **Target Vulnerabilities**:
  - Tray menus rendering off-screen or clipped by monitor edges.
  - SNI icon pixmap decoding errors causing tray crashes on legacy applications (e.g. Steam, Discord, Electron apps).
  - Zombie tray items persisting after application crashes without sending `ItemUnregistered`.
- **Methodology & Tooling**:
  - Test with diverse tray providers (Steam, Discord, OBS Studio, Nextcloud).
  - Verify right-click context menu positioning near screen borders.
- **Acceptance Criteria**: Pixel-aligned context menus, universal SNI icon compatibility, and automatic cleanup of dead tray items.

#### Subphase 5.6: Active Window Title, Battery & Keyboard Layout Popouts
- **Scope**: Window title widget, battery status card, keyboard layout switcher.
- **Files**: `ActiveWindow.qml`, `Battery.qml`, `LockStatus.qml`, `KbLayout.qml`.
- **Target Vulnerabilities**:
  - Window title overflowing container or causing layout stutter on long browser titles.
  - Battery time-remaining calculation dividing by zero when charging current reports 0.
  - Keyboard layout indicator failing to update when layout is switched via Hyprland keybind.
- **Methodology & Tooling**:
  - Test with very long window titles (500+ characters) and special unicode glyphs.
  - Switch keyboard layouts rapidly using compositor hotkeys.
- **Acceptance Criteria**: Clean text truncation with eliding, division-by-zero protected battery telemetry, and real-time layout updates.

---

### Phase 6: Dashboard, Performance Hub & Media Visualizer (`modules/dashboard/`)

#### Subphase 6.1: Dashboard Window Orchestration & Tab Management
- **Scope**: Dashboard sliding container, tab switcher, keyboard shortcuts.
- **Files**: `modules/dashboard/Dash.qml`, `Content.qml`, `Tabs.qml`, `Wrapper.qml`.
- **Target Vulnerabilities**:
  - Tab state desynchronization when opening dashboard via hotkey vs mouse click.
  - Focus retention when switching between Dashboard tabs.
  - Unloading inactive tabs causing lag spikes when clicking back to complex tabs (Performance/Media).
- **Methodology & Tooling**:
  - Measure frame rendering times during tab transitions.
  - Inspect QML component caching and memory consumption.
- **Acceptance Criteria**: Instantaneous tab switching (<16ms frame budget) with persistent state retention.

#### Subphase 6.2: Pomodoro Visual Widget & M3 Falling Shape Engine
- **Scope**: Pomodoro timer display, M3 translucent falling shapes animation, dual-mode clock switcher.
- **Files**: `modules/dashboard/dash/PomodoroShapes.qml`, `modules/dashboard/dash/DateTime.qml`.
- **Target Vulnerabilities**:
  - Shape physics / gravity calculation CPU overhead when dashboard remains open.
  - Shape boundaries clipping outside widget container.
  - Clock mode toggle (standard clock vs Pomodoro timer) state desynchronization.
- **Methodology & Tooling**:
  - Run GPU / CPU profiling while shapes are actively falling.
  - Verify boundary collision detection and shape count limits.
- **Acceptance Criteria**: Zero frame drops during shape animations, bounded object allocation, and smooth mode toggling.

#### Subphase 6.3: Calendar Logic, Time Displays & Small Weather Card
- **Scope**: Monthly calendar grid, date selection, agenda integration, weather widget.
- **Files**: `Calendar.qml`, `DateTime.qml`, `SmallWeather.qml`, `User.qml`.
- **Target Vulnerabilities**:
  - Calendar month transition bugs: leap years, months with 31 vs 30 days, week starting on Monday vs Sunday based on locale.
  - Weather temperature unit conversion errors (Celsius vs Fahrenheit).
  - User profile avatar missing or failing to render local user face icon.
- **Methodology & Tooling**:
  - Test calendar view on February 29 of leap years and boundary month changes.
  - Switch system locales (`en_US`, `de_DE`, `ja_JP`) and verify first day of week.
- **Acceptance Criteria**: 100% accurate calendar date math, locale-respecting week layouts, and robust user avatar resolution.

#### Subphase 6.4: Fullscreen Media Player, Visualizer Canvas & Synchronized Lyrics
- **Scope**: Media controls, album artwork, CAVA visualizer canvas, synchronized LRC lyrics.
- **Files**: `modules/dashboard/media/*`.
- **Target Vulnerabilities**:
  - LRC lyric timestamp parsing errors causing lyrics to get stuck or desynchronize.
  - Visualizer canvas repainting continuously even when music is paused, wasting GPU power.
  - Album art aspect ratio distortion on non-square covers.
- **Methodology & Tooling**:
  - Feed varied LRC formats (standard, enhanced word-by-word, missing timestamps).
  - Monitor GPU canvas repaint rates when media is playing vs paused.
- **Acceptance Criteria**: Perfectly synchronized lyric auto-scrolling, zero canvas activity during playback pauses, and proportional artwork scaling.

#### Subphase 6.5: Performance Hub: CPU, GPU, Memory, Storage & Network Cards
- **Scope**: Real-time hardware telemetry dashboard, graphs, sparklines, storage bars.
- **Files**: `modules/dashboard/performance/*`.
- **Target Vulnerabilities**:
  - Sparkline history buffer memory growth: unbounded ringbuffer storing metric points.
  - Division by zero in battery tank or storage cards when capacity is zero.
  - Graph rendering spikes causing frame drops when dashboard is opened.
- **Methodology & Tooling**:
  - Leave performance tab open for extended periods (1+ hours) and monitor memory footprint.
  - Stress CPU and memory to 100% and verify graph scaling limits.
- **Acceptance Criteria**: Fixed-size circular metric buffers, division-by-zero immunity, and 60 FPS graph rendering under load.

---

### Phase 7: Custom Dock & Overview Taskview Diagnostics (`modules/dock/`, `modules/overview/`)

#### Subphase 7.1: Dock Auto-Hide, Hover Proximity & Multi-Monitor Placement
- **Scope**: Dock container window, edge hover activation, auto-hide timers, multi-monitor configuration.
- **Files**: `modules/dock/Wrapper.qml`, `modules/dock/Content.qml`.
- **Target Vulnerabilities**:
  - Auto-hide timer glitches: dock hiding while cursor is still hovering over a context menu.
  - Edge hover activation dead zones or false-positive activations during full-screen video playback.
  - Multi-monitor placement conflicts: dock appearing on unintended monitors.
- **Methodology & Tooling**:
  - Test hover enter/leave event sequences with various mouse speeds.
  - Test dock behavior with full-screen and tiled windows in Hyprland.
- **Acceptance Criteria**: Reliable hover reveal without jitter, context menu hover lock, and precise screen targeting.

#### Subphase 7.2: Dock Item Management, Running Indicators & Context Menu
- **Scope**: Pinned application persistence, running instance badges, window cycling, context menu actions.
- **Files**: `modules/dock/DockContextMenu.qml`, `modules/dock/Content.qml`.
- **Target Vulnerabilities**:
  - Window cycling logic: clicking a running app icon failing to cycle through multiple open windows.
  - Unpinning / pinning apps failing to serialize changes to `settings.json`.
  - Context menu rendering partially off-screen at display edges.
- **Methodology & Tooling**:
  - Pin, unpin, rearrange applications and restart shell to verify persistence.
  - Launch multiple instances of the same application (e.g. terminal, browser) and cycle focus.
- **Acceptance Criteria**: Immediate setting persistence, accurate running instance indicators, and smart context menu placement.

#### Subphase 7.3: Overview Taskview Layer Architecture & Monitor Binding
- **Scope**: Overview full-screen overlay, monitor attachment, keyboard navigation entry.
- **Files**: `modules/overview/Overview.qml`, `OverviewContent.qml`, `OverviewState.qml`.
- **Target Vulnerabilities**:
  - Overview failing to open or opening on the wrong monitor when triggered via hotkey.
  - Keyboard grab failure: Esc key failing to dismiss overview, leaving user stuck.
  - Compositor event desynchronization: window closed while overview is open causing ghost windows.
- **Methodology & Tooling**:
  - Trigger overview across multi-monitor setups with different active monitors.
  - Close windows from terminal (`hyprctl dispatch closewindow ...`) while overview is visible.
- **Acceptance Criteria**: Guaranteed keyboard navigation, flawless multi-monitor targeting, and immediate live synchronization with compositor state.

#### Subphase 7.4: Live Window Thumbnail Rendering, Scaling & Coordinate Transforms
- **Scope**: Live window captures, thumbnail layout, aspect ratio calculations, workspace cards.
- **Files**: `WorkspaceCarousel.qml`, `WorkspaceCard.qml`, `MiniWindow.qml`, `GhostWorkspaceCard.qml`.
- **Target Vulnerabilities**:
  - Coordinate transform math errors: thumbnails positioned outside their workspace cards.
  - Aspect ratio distortion: windows squished or stretched when monitor aspect ratio differs.
  - Wayland screencopy / image capture memory leaks on rapid thumbnail generation.
- **Methodology & Tooling**:
  - Audit window coordinate scaling formulas (`(window.x - monitor.x) * scale`).
  - Profile image memory allocation during rapid carousel scrolling.
- **Acceptance Criteria**: Proportional window thumbnail scaling, accurate spatial placement, and leak-free capture handles.

#### Subphase 7.5: Drag-and-Drop Window Migration Between Workspaces
- **Scope**: Interactive mouse dragging of window thumbnails between workspace cards.
- **Files**: `WorkspaceCard.qml`, `MiniWindow.qml`, `OverviewContent.qml`.
- **Target Vulnerabilities**:
  - Drag-and-drop hitbox calculation errors dropping windows onto the wrong workspace.
  - Window focus hijacking during drag operations.
  - Hyprland dispatch failure: `hyprctl dispatch movetoworkspacesilent` failing on special characters in window address.
- **Methodology & Tooling**:
  - Drag windows between active, empty, and special workspaces.
  - Test boundary drop points (edges between adjacent workspace cards).
- **Acceptance Criteria**: Pixel-accurate drop target detection and reliable compositor window migration.

#### Subphase 7.6: All-Windows Search Grid, Keyboard Navigation & Focus Trap
- **Scope**: All-windows search grid, title/class filtering, arrow key navigation, selection actions.
- **Files**: `AllWindowsGrid.qml`, `Header.qml`, `NavigationFooter.qml`, `SegmentedNav.qml`.
- **Target Vulnerabilities**:
  - Keyboard focus trap: unable to navigate between header search bar and window grid using arrow keys.
  - Search filter latency or typing lag when many windows are open (30+ windows).
  - Selecting a window failing to focus and raise the window in Hyprland.
- **Methodology & Tooling**:
  - Test full keyboard navigation workflow (Tab, Arrow keys, Enter, Esc) without touching the mouse.
  - Measure search filter debounce and list re-ordering latency.
- **Acceptance Criteria**: Fluid keyboard-only navigation, sub-10ms search filtering, and instant window focus dispatch.

---

### Phase 8: Application Launcher, Search & Qalculate (`modules/launcher/`)

#### Subphase 8.1: Launcher Overlay Lifecycle & Input Grab
- **Scope**: Launcher window popup, input grab management, focus acquisition.
- **Files**: `modules/launcher/Wrapper.qml`, `Content.qml`, `SearchBar.qml`.
- **Target Vulnerabilities**:
  - Launcher opening without initial keyboard focus requiring manual click into search bar.
  - Focus loss when clearing search query.
  - Rapid toggle spamming (Super key pressed repeatedly) causing launcher to get stuck open.
- **Methodology & Tooling**:
  - Script rapid toggle sequences (`for i in {1..20}; do quickshell toggle launcher; sleep 0.05; done`).
  - Verify Wayland keyboard grab acquisition on every open event.
- **Acceptance Criteria**: Instantaneous focus acquisition, zero toggle race conditions, and reliable dismissal on Esc or background click.

#### Subphase 8.2: Fuzzy Search Engine Performance & Indexing
- **Scope**: Fuzzy match algorithms, indexing latency, query debouncing.
- **Files**: `utils/scripts/fuzzysort.js`, `utils/scripts/fzf.js`, `utils/Searcher.qml`.
- **Target Vulnerabilities**:
  - Garbage collection pressure from allocating thousands of temporary score objects per keystroke.
  - Search ranking anomalies: exact prefix matches ranking lower than obscure fuzzy matches.
  - UI freeze when searching large file systems or deep application lists.
- **Methodology & Tooling**:
  - Benchmark search execution times across queries of varying length (1 to 20 characters).
  - Inspect heap allocations during rapid typing.
- **Acceptance Criteria**: Sub-5ms search execution for 500+ items with zero perceptible UI typing latency.

#### Subphase 8.3: Launcher Item Providers: Apps, Actions, Wallpapers, Schemes, Themes
- **Scope**: Item category providers, action dispatchers, theme switcher.
- **Files**: `modules/launcher/items/*`, `modules/launcher/services/*`, `WallpaperList.qml`.
- **Target Vulnerabilities**:
  - Missing desktop actions (e.g. "New Private Window" for Firefox) in app item expansion.
  - Wallpaper preview loading blocking the UI thread during grid scrolling.
  - Theme switching from launcher failing to notify all active windows and shell components.
- **Methodology & Tooling**:
  - Test launching various applications (terminal, graphical, flatpak, steam games).
  - Switch themes and schemes directly from launcher and audit propagation latency.
- **Acceptance Criteria**: Complete desktop action support, asynchronous image loading, and instant theme synchronization.

#### Subphase 8.4: Qalculate Inline Math Evaluation & Syntax Error Traps
- **Scope**: Inline calculator provider, mathematical expression evaluation, currency conversions.
- **Files**: `modules/launcher/items/CalcItem.qml`, `plugin/src/Caelestia/qalculator.cpp`.
- **Target Vulnerabilities**:
  - Calculator triggering on non-math queries (false positive activation on regular search text).
  - Division by zero or syntax errors resulting in `inf`, `nan`, or crash.
  - Long-running calculation blocking the main UI thread.
- **Methodology & Tooling**:
  - Test math inputs: `1+1`, `sqrt(144)`, `sin(pi/2)`, `100 USD to EUR`, `1/0`, `999999999!`.
  - Verify non-math strings do not invoke calculator evaluation.
- **Acceptance Criteria**: Strict math syntax heuristics, division-by-zero protection, and instantaneous calculation display.

#### Subphase 8.5: Terminal Command Execution Wrapper & Shell Injection Audit
- **Scope**: Terminal command launcher, script execution wrappers.
- **Files**: `assets/wrap_term_launch.sh`, `modules/launcher/services/Apps.qml`.
- **Target Vulnerabilities**:
  - Command injection via unquoted arguments in `wrap_term_launch.sh`.
  - Terminal emulator auto-detection failure when user's default terminal is uncommon (kitty, alacritty, foot, ghostty, wezterm).
  - Environment variable stripping when launching terminal commands.
- **Methodology & Tooling**:
  - Launch commands containing spaces, quotes, and pipes (`echo "Hello World" | grep Hello`).
  - Test launcher with various installed terminal emulators.
- **Acceptance Criteria**: Secure parameter escaping, broad terminal emulator support, and clean environment inheritance.

---

### Phase 9: Nexus Settings Center & System Configuration Audit (`modules/nexus/`)

#### Subphase 9.1: Nexus Navigation Framework & Dynamic Page Loader
- **Scope**: Nexus window, navigation pane, page routing, dynamic component instantiation.
- **Files**: `modules/nexus/Nexus.qml`, `NavPane.qml`, `PageRegistry.qml`, `PageCompRegistry.qml`, `WindowFactory.qml`, `NexusState.qml`.
- **Target Vulnerabilities**:
  - Memory leak when navigating through pages: previously loaded pages remaining in memory without proper cleanup.
  - Deep navigation history stack overflow or back button navigation loops.
  - Broken page links or missing registry entries causing blank pages.
- **Methodology & Tooling**:
  - Cycle through all pages in sequence while monitoring memory consumption in Heaptrack / System Monitor.
  - Validate all page IDs against `PageRegistry.qml`.
- **Acceptance Criteria**: Clean page destruction / caching policy, reliable back/forward navigation, and 100% valid page routes.

#### Subphase 9.2: Hardware & Connectivity Pages
- **Scope**: Network settings, Bluetooth pairing, Audio routing and volume mixer.
- **Files**: `NetworkPage.qml`, `BluetoothPage.qml`, `AudioPage.qml`, `modules/nexus/pages/audio/*`, `pages/bluetooth/*`, `pages/network/*`.
- **Target Vulnerabilities**:
  - Network detail page failing on ethernet interfaces with no Wi-Fi capabilities.
  - Bluetooth device pairing dialog hanging if device rejects passkey.
  - Audio page volume sliders failing to update when external volume changes occur.
- **Methodology & Tooling**:
  - Test network page with ethernet-only and Wi-Fi-only connections.
  - Attempt pairing with a rejected Bluetooth PIN.
- **Acceptance Criteria**: Comprehensive error states, bi-directional audio volume synchronization, and graceful pairing timeout handling.

#### Subphase 9.3: Shell Customization & Panel Configuration Pages
- **Scope**: Panels configuration, Dock settings, Overview options, Lock Screen settings.
- **Files**: `PanelsPage.qml`, `DockPanel.qml`, `OverviewPanel.qml`, `TaskbarPanel.qml`, `LockScreenPage.qml`.
- **Target Vulnerabilities**:
  - Changing panel positions (e.g. taskbar from Top to Bottom) causing visual glitching or requiring shell restart.
  - Setting invalid numerical ranges for dock thresholds or slot limits.
  - Pattern lock recording dialog failing to save pattern to `lockconfig`.
- **Methodology & Tooling**:
  - Change every setting option across all panel configuration pages.
  - Verify live updates in running shell and check persisted `settings.json`.
- **Acceptance Criteria**: Instantaneous live updates for all customization settings without requiring shell restarts.

#### Subphase 9.4: Wallpaper & Dynamic Theme Manager
- **Scope**: Theme picker, wallpaper categories, color variant selector, desktop background settings.
- **Files**: `WallpaperAndStyle.qml`, `ThemeSelect.qml`, `DesktopBackground.qml`, `ColourSelect.qml`, `WallpaperSelect.qml`.
- **Target Vulnerabilities**:
  - Broken image thumbnail generation for user-added wallpaper directories.
  - Dynamic theme assets (GIFs, notification backgrounds) failing to copy or link properly.
  - Selecting a theme failing to update the desktop clock position or background visualizer settings.
- **Methodology & Tooling**:
  - Switch between all bundled themes (Deadpool, Gojo, Berserk, LOTM, Pikachu, Shinchan, Abstract_Purple).
  - Verify all theme-specific assets (`sessionGif`, `mediaGif`, `lockGif`, `notifBg`, `defaultWall`) load correctly.
- **Acceptance Criteria**: Seamless theme switching, zero missing asset errors, and accurate color role derivation.

#### Subphase 9.5: System Services & Power Management Pages
- **Scope**: Notification settings, idle timeouts, battery thresholds, about page.
- **Files**: `ServicesPage.qml`, `PowerIdlePage.qml`, `NotificationsPage.qml`, `AboutPage.qml`.
- **Target Vulnerabilities**:
  - Idle timeout sliders allowing 0-second timeouts (instant locking loop).
  - About page version string displaying "unknown" when git repository information is missing.
  - Notification blacklist failing to persist excluded application names.
- **Methodology & Tooling**:
  - Boundary test all timeout and threshold sliders.
  - Check version reporting in compiled release builds.
- **Acceptance Criteria**: Enforced minimum threshold limits, accurate version reporting, and persistent notification rules.

---

### Phase 10: Notifications, OSD, Utilities & Area Picker (`modules/notifications/`, `modules/osd/`, `modules/utilities/`, `modules/areapicker/`, `modules/sidebar/`)

#### Subphase 10.1: Notification Banners, Stacking & Action Dispatch
- **Scope**: Desktop notification popups, stacking order, progress bars, action buttons.
- **Files**: `modules/notifications/Content.qml`, `Notification.qml`, `Wrapper.qml`.
- **Target Vulnerabilities**:
  - Notifications overlapping each other or overflowing screen boundaries.
  - Notification action buttons failing to invoke D-Bus `ActionInvoked` signals.
  - Long notification bodies breaking layout or pushing action buttons off-screen.
- **Methodology & Tooling**:
  - Send test notifications with multiple actions and progress bars using `notify-send`.
  - Test notifications with massive text blocks and varied urgency levels (low, normal, critical).
- **Acceptance Criteria**: Clean vertical stacking, guaranteed action invocation, and bounded card dimensions with text scrolling.

#### Subphase 10.2: On-Screen Displays (OSD) Volume/Brightness Popups
- **Scope**: Volume, microphone mute, brightness, and caps lock on-screen popups.
- **Files**: `modules/osd/Content.qml`, `Wrapper.qml`.
- **Target Vulnerabilities**:
  - Rapid volume key spamming causing OSD animation stutter or multiple stacked popups.
  - OSD dismiss timer getting cancelled and leaving OSD permanently visible on screen.
  - Caps lock / num lock indicator desynchronization from physical keyboard LED.
- **Methodology & Tooling**:
  - Spam volume and brightness hotkeys using automation scripts.
  - Verify timer resets and single-instance popup rendering.
- **Acceptance Criteria**: Fluid debounced animations, reliable auto-dismiss (<2000ms), and synchronized lock state indicators.

#### Subphase 10.3: Notification History Sidebar & Dock
- **Scope**: Notification center drawer, grouped notifications, dismiss all animation, quick toggles.
- **Files**: `modules/sidebar/*`.
- **Target Vulnerabilities**:
  - "Clear All" action failing to clean up notification group headers.
  - Notification count badge in taskbar desynchronizing from actual unread count.
  - Performance lag when opening sidebar with 50+ notifications stored in history.
- **Methodology & Tooling**:
  - Populate notification center with 50+ mixed notifications and test grouping and deletion.
  - Profile sidebar opening animation with populated history.
- **Acceptance Criteria**: Sub-frame animation smoothness, synchronized badge counts, and instantaneous history clearing.

#### Subphase 10.4: Utilities Panel, Quick Toggles & Recording Manager
- **Scope**: Utilities drawer, screen recording controls, recording file list, delete modal, toast popups.
- **Files**: `modules/utilities/*`.
- **Target Vulnerabilities**:
  - Recording delete modal deleting wrong file due to stale index in model.
  - Toast notifications piling up and covering utility controls.
  - Quick toggle button state desynchronization (e.g. idle inhibitor shown active when disabled).
- **Methodology & Tooling**:
  - Test recording, playing, and deleting screen captures.
  - Verify confirmation modal safety before executing file unlinks.
- **Acceptance Criteria**: Safe file deletion confirmations, self-cleaning toast notifications, and accurate toggle state indicators.

#### Subphase 10.5: Wayland Interactive Area Picker & Coordinate Capture
- **Scope**: Interactive rectangular area selection overlay for screenshots and recordings.
- **Files**: `modules/areapicker/AreaPicker.qml`, `Picker.qml`.
- **Target Vulnerabilities**:
  - Coordinate calculation errors across multi-monitor setups with negative offsets or differing scales.
  - Selection box drawing inverted dimensions when dragging bottom-right to top-left.
  - Input grab failure leaving screen frozen or unclickable if selection is aborted with Esc.
- **Methodology & Tooling**:
  - Drag selection boxes in all four diagonal directions on single and multi-monitor setups.
  - Cancel area selection with Esc and right-click to test input grab releases.
- **Acceptance Criteria**: Accurate multi-monitor normalized coordinates, omnidirectional drag selection, and clean grab release.

---

### Phase 11: Design System, UI Components & Animation Performance (`components/`)

#### Subphase 11.1: Core Button & Interactive Controls
- **Scope**: Base buttons, icon buttons, split buttons, state layers, ripple feedback.
- **Files**: `components/controls/ButtonBase.qml`, `IconButton.qml`, `IconTextButton.qml`, `SplitButton.qml`, `TextButton.qml`, `StateLayer.qml`.
- **Target Vulnerabilities**:
  - Hitbox dead zones: mouse clicks near button borders not registering.
  - Missing visual focus indicators when navigating via keyboard Tab key.
  - Ripple effect animation objects leaking memory on repeated clicks.
- **Methodology & Tooling**:
  - Automate rapid clicking (100 clicks/sec) on buttons and monitor memory heap.
  - Audit keyboard accessibility focus states.
- **Acceptance Criteria**: Full keyboard accessibility, 100% reliable hitboxes, and bounded state layer memory usage.

#### Subphase 11.2: Sliders, Progress Bars & Range Inputs
- **Scope**: Continuous and stepped sliders, filled sliders, circular progress bars.
- **Files**: `StyledSlider.qml`, `FilledSlider.qml`, `CircularProgress.qml`, `StyledProgressBar.qml`.
- **Target Vulnerabilities**:
  - Slider value jumping to 0 or 1 on initial click due to coordinate normalization bugs.
  - Mouse drag escaping slider bounds causing stuck drag states.
  - Stepped slider rounding errors skipping defined increments.
- **Methodology & Tooling**:
  - Test dragging beyond component bounds and releasing mouse outside the window.
  - Verify boundary values (minimum, maximum, middle increments).
- **Acceptance Criteria**: Smooth continuous tracking, boundary clamping, and reliable mouse release detection outside boundaries.

#### Subphase 11.3: Text Inputs, Spinboxes & Search Bars
- **Scope**: Styled text fields, password fields, search bars, spinboxes.
- **Files**: `StyledTextField.qml`, `TextFieldBase.qml`, `SearchBar.qml`, `StyledSpinBox.qml`.
- **Target Vulnerabilities**:
  - Text input losing cursor position during dynamic text changes.
  - Search bar clear button ("X") failing to restore focus to input.
  - Spinbox numerical underflow or overflow when typing arbitrary text.
- **Methodology & Tooling**:
  - Input non-numeric strings into spinboxes, paste massive text blocks into search bars.
  - Test keyboard shortcut interactions (Ctrl+A, Ctrl+C, Ctrl+V, Backspace).
- **Acceptance Criteria**: Strict input validation, persistent cursor positioning, and robust clipboard handling.

#### Subphase 11.4: Scrollable Containers & Virtualized Flickables
- **Scope**: Flickables, list views, fade masks, scrollbars.
- **Files**: `components/containers/*`.
- **Target Vulnerabilities**:
  - Flickable wheel deceleration glitches (`QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000`).
  - Fade mask shaders causing GPU overhead on low-end hardware.
  - Scrollbar thumb sizing bugs when list content is smaller than viewport height.
- **Methodology & Tooling**:
  - Test mouse wheel, trackpad scrolling, and scrollbar thumb dragging across all scrollable views.
  - Verify fade mask transparency blending.
- **Acceptance Criteria**: Natural deceleration, zero scrollbar thumb glitches, and performant viewport clipping.

#### Subphase 11.5: Image Loaders, Caching & Fallbacks
- **Scope**: Image loading components, fade-in transitions, caching wrappers.
- **Files**: `components/images/*`.
- **Target Vulnerabilities**:
  - Broken image URLs causing blank white rectangles or console error floods.
  - Asynchronous image loading causing visible layout shifts as images pop in.
  - Image cache retaining high-resolution textures indefinitely.
- **Methodology & Tooling**:
  - Test image components with missing files, invalid URLs, and zero-byte files.
  - Verify fallback placeholder rendering.
- **Acceptance Criteria**: Graceful placeholder fallbacks, layout-stable loading, and bounded cache lifecycles.

#### Subphase 11.6: Animation Framework & Frame Drops
- **Scope**: Animation wrappers, spring curves, transitions.
- **Files**: `AnchorAnim.qml`, `Anim.qml`, `CAnim.qml`, `AnimLoader.qml`.
- **Target Vulnerabilities**:
  - Binding loops created by animations modifying properties that affect animation triggers.
  - Animations running in background when components are invisible, wasting GPU cycles.
  - Unsynchronized duration values between paired entry and exit animations.
- **Methodology & Tooling**:
  - Audit animations with `QSG_RENDER_TIMING=1` to detect dropped frames during drawer transitions.
  - Verify animations are stopped when parent `visible: false`.
- **Acceptance Criteria**: Zero frame drops, zero binding loops, and guaranteed animation stoppage when hidden.

#### Subphase 11.7: Custom File Dialog & Breadcrumb Traversal
- **Scope**: Embedded file picker, folder browsing, breadcrumbs, size formatters.
- **Files**: `components/filedialog/*`.
- **Target Vulnerabilities**:
  - Path traversal vulnerability when navigating to parent directories (`../../`).
  - Permission denied error handling when entering restricted directories (e.g. `/root`).
  - Hidden file toggle state desynchronization.
- **Methodology & Tooling**:
  - Navigate to restricted directories, symlinks, and folders with thousands of files.
  - Verify file selection and cancellation callbacks.
- **Acceptance Criteria**: Safe path resolution, graceful access-denied handling, and responsive file listing.

---

### Phase 12: External Scripts, Daemons & Build System (`scripts/`, `install.sh`, `flake.nix`, CMake)

#### Subphase 12.1: Python Bluetooth Pairing Daemon
- **Scope**: BlueZ D-Bus agent script.
- **Files**: `scripts/bt-agent.py`, `services/BtAgent.qml`.
- **Target Vulnerabilities**:
  - Unhandled D-Bus exceptions when BlueZ service restarts.
  - Security risk: auto-authorizing pairing requests without user confirmation in GUI.
  - Compatibility with Python 3.12, 3.13, 3.14 (asyncio event loop and D-Bus library bindings).
- **Methodology & Tooling**:
  - Run static type checking and linting on `bt-agent.py`.
  - Simulate pairing requests requiring PIN codes, Passkeys, and Yes/No confirmations.
- **Acceptance Criteria**: Secure user-confirmed pairing flow, automatic reconnection to D-Bus, and Python 3.12+ compatibility.

#### Subphase 12.2: Shell Launchers & Environment Scripts
- **Scope**: Startup script, local test runner, fish script.
- **Files**: `scripts/startup-shell.sh`, `scripts/run-local-shell.sh`, `scripts/trs.fish`.
- **Target Vulnerabilities**:
  - Environment variable pollution when running multiple instances of the shell.
  - Hardcoded paths to user home directories or specific package manager binaries.
  - Missing executable permissions on startup scripts.
- **Methodology & Tooling**:
  - Test scripts under clean environment (`env -i`).
  - Check POSIX compliance and fish shell syntax.
- **Acceptance Criteria**: Portable, robust shell execution with proper environment sandboxing.

#### Subphase 12.3: Installation & Update Automation Scripts
- **Scope**: Installation script, update manager, dependency checks.
- **Files**: `install.sh`, `update.sh`.
- **Target Vulnerabilities**:
  - Destructive operations: overwriting existing user configurations without backup.
  - Unchecked package manager commands: assuming Arch Linux (`pacman`/`yay`) without verifying Debian/Fedora/Nix.
  - Unhandled errors during `git pull` or `cmake --build`.
- **Methodology & Tooling**:
  - Execute dry-run installation on virtual machines or clean containers.
  - Verify error handling and backup creation before file overwrites.
- **Acceptance Criteria**: Safe user config backups, multi-distro detection, and non-destructive update routines.

#### Subphase 12.4: CMake Build System, Compiler Flags & Package Rules
- **Scope**: Root and subproject CMake files, install targets, packaging rules.
- **Files**: `CMakeLists.txt`, `plugin/CMakeLists.txt`, `extras/CMakeLists.txt`.
- **Target Vulnerabilities**:
  - Missing dependency checks: CMake succeeding when required libraries (PipeWire, libsensors, Qt6 modules) are missing.
  - Hardcoded install paths violating GNUInstallDirs standards.
  - Missing compiler hardening flags (`-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`).
- **Methodology & Tooling**:
  - Run CMake with missing optional dependencies to verify graceful feature disabling.
  - Check installed package layout against Linux FHS standards.
- **Acceptance Criteria**: Complete dependency validation, hardened compiler flags, and compliant install targets.

#### Subphase 12.5: Nix Flake & Home-Manager Module Consistency
- **Scope**: Nix flakes, derivations, Home Manager modules.
- **Files**: `flake.nix`, `flake.lock`, `nix/default.nix`, `nix/hm-module.nix`.
- **Target Vulnerabilities**:
  - Outdated inputs in `flake.lock` causing build failures against nixpkgs-unstable.
  - Missing runtime dependencies in derivation `buildInputs` (e.g. Python libraries, sound tools).
  - Home Manager module option type mismatches.
- **Methodology & Tooling**:
  - Validate with `nix flake check` and test build in isolated Nix sandbox (`nix build`).
- **Acceptance Criteria**: Reproducible, error-free Nix build passing all flake checks.

---

### Phase 13: Runtime Stress Testing, Leak Detection & Edge Case Validation

#### Subphase 13.1: Multi-Monitor Hotplug & Resolution Switching Stress Tests
- **Scope**: Runtime multi-monitor behavior, scaling changes, output removal.
- **Actions**:
  - Connect and disconnect virtual displays in rapid succession using Hyprland commands.
  - Change display scale factors dynamically between 1.0, 1.25, 1.5, 2.0.
- **Target Vulnerabilities**:
  - Segmentation faults when active surfaces lose their output display.
  - Layer shell surfaces failing to reposition after resolution change.
- **Acceptance Criteria**: Zero crashes on monitor hotplug/unplug and instant surface repositioning.

#### Subphase 13.2: Rapid Interaction, Panel Spamming & Gesture Boundary Fuzzing
- **Scope**: Concurrent user inputs, rapid hotkey triggers, gesture interrupts.
- **Actions**:
  - Simultaneously trigger hotkeys for Launcher, Overview, Dashboard, and Sidebar.
  - Interrupt sliding drawer animations midway with mouse clicks.
- **Target Vulnerabilities**:
  - State machine deadlock leaving multiple modal surfaces active simultaneously.
  - Corrupted animation state leaving drawers stuck half-open.
- **Acceptance Criteria**: Resilient state transitions handling rapid concurrent inputs gracefully without deadlocks.

#### Subphase 13.3: Memory Leak, Object Lifespan & File Descriptor Profiling
- **Scope**: Long-duration stability, memory leaks, file descriptor usage.
- **Actions**:
  - Run the shell for 4+ hours under synthetic automated user interaction (open/close drawers, play music, switch workspaces).
  - Monitor memory resident set size (RSS) and open file descriptor count (`lsof -p <pid>`).
- **Target Vulnerabilities**:
  - Creeping memory consumption exceeding 500MB RSS.
  - File descriptor leaks in `/proc`, `/sys`, or D-Bus connections.
- **Acceptance Criteria**: Flat memory profile over extended uptime (<50MB growth over 4 hours) and constant file descriptor count.

#### Subphase 13.4: Hyprland Crash / Restart Recovery Simulation
- **Scope**: Compositor crash survival, socket reconnection, surface recreation.
- **Actions**:
  - Restart Hyprland compositor while shell is running.
  - Terminate Wayland socket connection abruptly.
- **Target Vulnerabilities**:
  - Shell entering 100% CPU busy-loop trying to read dead socket.
  - Crashing immediately without attempting graceful reconnect or exit.
- **Acceptance Criteria**: Graceful handling of compositor socket loss without spinning CPU or corrupting user data.

#### Subphase 13.5: Disconnected Hardware & Missing Subsystem Fault Injection
- **Scope**: Running shell on systems with missing hardware components.
- **Actions**:
  - Test on machines with no battery (desktop PC), no Wi-Fi adapter, no Bluetooth controller, no PipeWire daemon running.
- **Target Vulnerabilities**:
  - Crashing on startup because battery or wireless interfaces are missing.
  - Console flooding with thousands of errors per second.
- **Acceptance Criteria**: Silent, graceful degradation disabling unbacked widgets without affecting core shell stability.

---

### Phase 14: Final Synthesis, Remediation Prioritization & Executive Diagnostic Report

#### Subphase 14.1: Aggregation & Triage of All Logged Defect Manifests
- **Scope**: All defects cataloged across Phases 0 through 13.
- **Actions**:
  - Compile the complete defect register with file locations, line numbers, and reproduction steps.
  - Assign final severity ratings (P0 through P4) based on real-world impact.
- **Acceptance Criteria**: Unified, deduplicated defect catalog signed off by engineering.

#### Subphase 14.2: Root Cause Mapping & Systemic Architectural Debt Assessment
- **Scope**: Systemic issues, recurrent anti-patterns, design bottlenecks.
- **Actions**:
  - Map individual bugs to root architectural causes (e.g. missing error boundary patterns, improper QML ownership models).
  - Quantify technical debt and calculate remediation effort estimates.
- **Acceptance Criteria**: Comprehensive architectural health assessment identifying foundational improvements.

#### Subphase 14.3: Remediation Master Plan & Patches Formulation
- **Scope**: Fix planning, patch sequence, regression prevention.
- **Actions**:
  - Formulate atomic patch sets ordered by priority (P0 Blocker fixes first, followed by P1, P2, P3, P4).
  - Define regression testing guidelines for each patch group.
- **Acceptance Criteria**: Actionable step-by-step remediation guide with zero risk of breaking existing features.

#### Subphase 14.4: Executive Diagnostic Audit Report Publication
- **Scope**: Final documentation, executive scorecard, sign-off.
- **Actions**:
  - Publish the final audit summary report detailing codebase health, discovered bugs, and verification results.
  - Update `COMPLETION.md` with final audit status.
- **Acceptance Criteria**: Complete, transparent diagnostic report ready for developer review and execution.
