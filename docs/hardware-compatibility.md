# 💻 Hardware Compatibility & Portability Layer

This custom build of Caelestia Shell incorporates a cross-hardware portability layer to ensure reliable performance across a wide variety of hardware configurations.

---

## 🎯 Supported Hardware

### 1. Multi-Vendor GPU Monitoring (`gpu.cpp`)
The C++ GPU monitoring service dynamically probes available graphics hardware without hardcoded paths:

- **Intel Integrated & Arc Graphics**:
  - Full support for traditional **i915** driver sysfs structures (`/sys/class/drm/card*/gt/`).
  - Native multi-tile support for modern **Intel Xe** kernel drivers (`/sys/class/drm/card*/gt/gt*/` engines).
  - Accurate frequency, render busy percentage, and power telemetry.
- **AMD Radeon Graphics**:
  - Automatic `amdgpu` sysfs discovery (`gpu_busy_percent`, `pp_dpm_sclk`).
  - VRAM usage and temperature metrics.
- **NVIDIA Dedicated Graphics**:
  - Automatic parsing via `nvidia-smi` daemon queries.
- **Headless / Virtual Machines (QEMU / KVM / Proxmox)**:
  - Graceful fallback detection preventing crashes when no dedicated GPU sensors exist.

---

### 2. Bluetooth Pairing Agent (`bt-agent.py`)
- Standalone Python daemon registering `org.bluez.Agent1` on the system D-Bus with `KeyboardDisplay` capabilities.
- Handles PIN codes, 6-digit numeric passkeys, and authorization requests via a local UNIX socket bridge to QML.
- Wrapped with graceful D-Bus connection exception handling so computers without Bluetooth hardware run completely error-free.

---

### 3. Audio Stream Resilience (`Audio.qml`)
- Null-device filtering prevents application crashes when audio devices are dynamically unplugged, Bluetooth headsets disconnect, or PipeWire is restarted.

---

### 4. PAM Lock Screen State Handling (`Pam.qml`)
- Uses native Qt/QML PAM enum states (`Pam.Failed`, `Pam.Authenticated`, etc.) preventing lock surface deadlocks and displaying toast error feedback on incorrect passwords or rejected patterns.
