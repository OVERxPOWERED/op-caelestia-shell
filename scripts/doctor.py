#!/usr/bin/env python3
"""Health checks behind Nexus > Doctor.

    doctor.py check        print a JSON list of checks (read-only)
    doctor.py check --watch  the same, minus the slow or noisy ones, for the background watchdog
    doctor.py fix <id> [arg]  run the one safe fix a check offers

Checks never change anything. Fixes only touch what they name: user services, rfkill, extra copies of our own
bt-agent.py, the polkit agent, and a saved Wi-Fi profile the user picks by UUID.
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
ROOT = Path(__file__).resolve().parent.parent


def run(*cmd, timeout=8):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except (OSError, subprocess.TimeoutExpired):
        return 127, "", ""


def active(unit, user=False):
    args = ["systemctl"] + (["--user"] if user else []) + ["is-active", unit]
    return run(*args)[1] == "active"


def check(id, title, status, detail, fix=None, fix_label=None, hint=None, items=None):
    return {"id": id, "title": title, "status": status, "detail": detail,
            "fix": fix, "fixLabel": fix_label, "hint": hint, "items": items or []}


def procs(match):
    """[(pid, argv)] of processes whose argv matches, without matching ourselves."""
    out = []
    for p in Path("/proc").iterdir():
        if not p.name.isdigit() or int(p.name) == os.getpid():
            continue
        try:
            argv = (p / "cmdline").read_bytes().split(b"\0")
            argv = [a.decode(errors="replace") for a in argv if a]
        except OSError:
            continue
        if argv and match(argv):
            out.append((int(p.name), argv))
    return sorted(out)


def bt_agents():
    return procs(lambda a: a[0].endswith(("python", "python3")) and any(x.endswith("scripts/bt-agent.py") for x in a[1:3]))


# ---------------------------------------------------------------- checks

def c_network():
    if active("NetworkManager"):
        return check("network", "NetworkManager", "ok", "Running")
    return check("network", "NetworkManager", "bad", "Not running, so Wi-Fi and Ethernet are unavailable",
                 hint="sudo systemctl restart NetworkManager")


def c_bluetooth():
    if active("bluetooth"):
        return check("bluetooth", "Bluetooth service", "ok", "Running")
    return check("bluetooth", "Bluetooth service", "bad", "Not running",
                 hint="sudo systemctl restart bluetooth")


def c_rfkill():
    rc, out, _ = run("rfkill", "-n", "-o", "TYPE,SOFT,HARD")
    if rc != 0:
        return check("rfkill", "Radios", "info", "rfkill is not available")
    soft, hard = [], []
    for line in out.splitlines():
        t = line.split()
        if len(t) == 3 and t[0] in ("wlan", "bluetooth"):
            if t[2] == "blocked":
                hard.append(t[0])
            elif t[1] == "blocked":
                soft.append(t[0])
    if hard:
        return check("rfkill", "Radios", "bad", f"Hardware switch blocks: {', '.join(hard)}",
                     hint="Check the laptop's airplane-mode key or switch")
    if soft:
        return check("rfkill", "Radios", "warn", f"Switched off in software: {', '.join(soft)}",
                     fix="rfkill", fix_label="Switch on")
    return check("rfkill", "Radios", "ok", "Wi-Fi and Bluetooth are not blocked")


def c_btagent():
    n = len(bt_agents())
    if n == 1:
        return check("btagent", "Bluetooth pairing helper", "ok", "One copy running")
    if n == 0:
        return check("btagent", "Bluetooth pairing helper", "warn", "Not running, so pairing requests may not show a prompt",
                     hint="It starts with the shell; restart the shell to bring it back")
    return check("btagent", "Bluetooth pairing helper", "warn", f"{n} copies running; they fight over pairing requests",
                 fix="btagent", fix_label="Keep one")


def c_shell_copies():
    shells = procs(lambda a: os.path.basename(a[0]) in ("quickshell", "qs") and "-p" in a)
    if len(shells) <= 1:
        return check("shells", "Shell instances", "ok", "One shell running")
    return check("shells", "Shell instances", "warn", f"{len(shells)} shells running at once (doubled panels, double notifications)",
                 hint="Log out and back in, or kill the extra quickshell processes")


KEPT = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caelestia/doctor-wifi-kept.json"


def kept_profiles():
    try:
        return set(json.loads(KEPT.read_text()))
    except (OSError, ValueError, TypeError):
        return set()


def wifi_dupes():
    """[(uuid, name, last_used_epoch)] of saved Wi-Fi profiles that look like leftovers: a name
    saved twice, or "<name> <n>" while "<name>" also exists. None if NetworkManager can't be read."""
    rc, out, _ = run("nmcli", "-t", "-f", "NAME,UUID,TIMESTAMP,TYPE", "connection", "show")
    if rc != 0:
        return None, 0
    profiles = []
    for line in out.splitlines():
        # NAME may contain escaped colons; the other fields never do
        parts = re.split(r"(?<!\\):", line)
        if len(parts) == 4 and parts[3] == "802-11-wireless":
            profiles.append((parts[1], parts[0].replace("\\:", ":"), int(parts[2] or 0)))
    names = [n for _, n, _ in profiles]
    found = []
    for uuid, name, ts in profiles:
        m = re.match(r"^(.*\S) (\d+)$", name)
        if names.count(name) > 1 or (m and m.group(1) in names):
            found.append((uuid, name, ts))
    kept = kept_profiles()
    found = [f for f in found if f[0] not in kept]
    return sorted(found, key=lambda t: (t[1], t[2])), len(profiles)


def c_wifi_dupes():
    found, total = wifi_dupes()
    if found is None:
        return check("wifidupes", "Saved Wi-Fi profiles", "info", "Could not read profiles")
    if not found:
        return check("wifidupes", "Saved Wi-Fi profiles", "ok", f"{total} saved, no duplicates")
    items = []
    for uuid, name, ts in found:
        used = time.strftime("last used %d %b %Y", time.localtime(ts)) if ts else "never used"
        items.append({"label": name, "sub": used, "fix": "forget", "arg": uuid, "fixLabel": "Forget", "confirm": True,
                      "keepArg": uuid})
    return check("wifidupes", "Saved Wi-Fi profiles", "warn", f"{len(found)} look like leftovers; you choose which to forget",
                 hint="Forget the ones you don't want. Press Keep on the ones you do, and they stop being listed.", items=items)


POLKIT_AGENT = "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"


def c_polkit():
    agents = procs(lambda a: re.search(r"polkit.*(agent|gnome|kde|lxqt|mate)|hyprpolkitagent|lxpolkit", os.path.basename(a[0]), re.I) is not None)
    if agents:
        return check("polkit", "Authentication prompts", "ok", "A polkit agent is running")
    msg = "No polkit agent is running, so apps cannot ask for your password (mounting, system settings, some updates)"
    if os.access(POLKIT_AGENT, os.X_OK):
        return check("polkit", "Authentication prompts", "warn", msg, fix="polkit", fix_label="Start it",
                     hint="It is in your startup list but is not running now; it may have died or failed to start at login")
    return check("polkit", "Authentication prompts", "warn", msg,
                 hint="Install one: sudo pacman -S polkit-gnome, then start it at login")


def c_portal():
    down = [u for u in ("xdg-desktop-portal", "xdg-desktop-portal-hyprland") if not active(u, user=True)]
    if not down:
        return check("portal", "Screen share portals", "ok", "Running")
    return check("portal", "Screen share portals", "bad", f"Not running: {', '.join(down)}. Screen sharing and file pickers will fail",
                 fix="portal", fix_label="Restart")


def c_audio():
    down = [u for u in ("pipewire", "wireplumber") if not active(u, user=True)]
    if not down:
        return check("audio", "Audio", "ok", "PipeWire and WirePlumber running")
    return check("audio", "Audio", "bad", f"Not running: {', '.join(down)}", fix="audio", fix_label="Restart")


def c_monitors():
    rc, out, _ = run("hyprmoncfg", "doctor")
    if rc == 127:
        return check("monitors", "Monitor profiles", "info", "hyprmoncfg is not installed")
    first = out.splitlines()[0] if out else ""
    if first.startswith("OK"):
        rc2, mon, _ = run("hyprctl", "monitors", "-j")
        try:
            names = [m["name"] for m in json.loads(mon)]
        except (ValueError, TypeError):
            names = []
        if names and all(n == "FALLBACK" for n in names):
            return check("monitors", "Monitor profiles", "bad", "No real display is active (only Hyprland's placeholder)",
                         hint="Replug the display or use the Display page to re-enable one")
        return check("monitors", "Monitor profiles", "ok", "Layouts load at startup")
    return check("monitors", "Monitor profiles", "warn", first or "hyprmoncfg doctor reported a problem",
                 hint="Run `hyprmoncfg doctor` in a terminal for details")


DISMISS = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caelestia/doctor-crashes-dismissed"


def dismissed_at():
    try:
        return float(DISMISS.read_text())
    except (OSError, ValueError):
        return 0.0


def c_crashes():
    notable = ("Hyprland", "quickshell", "xdg-desktop-portal", "hyprsunset", "pipewire", "wireplumber", "NetworkManager", "bluetoothd")
    rc, out, _ = run("coredumpctl", "list", "--no-pager", "--no-legend", "--since", "-3days", timeout=15)
    hits = {}
    if rc == 0:
        for line in out.splitlines():
            exe = next((t for t in line.split() if t.startswith("/")), "")
            base = os.path.basename(exe)
            when = re.match(r"\w{3} (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)", line.strip())
            try:
                at = time.mktime(time.strptime(when.group(1), "%Y-%m-%d %H:%M:%S"))
            except (AttributeError, ValueError):
                at = time.time()
            if at > dismissed_at() and any(base.startswith(n) for n in notable):
                hits[base] = hits.get(base, 0) + 1
    crash_dir = HOME / ".cache/quickshell/crashes"
    recent = 0
    if crash_dir.is_dir():
        cutoff = max(time.time() - 3 * 86400, dismissed_at())
        recent = sum(1 for d in crash_dir.iterdir() if d.stat().st_mtime > cutoff)
    if recent:
        hits["quickshell (own report)"] = recent
    if not hits:
        return check("crashes", "Recent crashes", "ok", "Nothing important crashed in the last 3 days")
    summary = ", ".join(f"{k} x{v}" for k, v in sorted(hits.items()))
    return check("crashes", "Recent crashes", "warn", f"In the last 3 days: {summary}",
                 fix="crashes", fix_label="Dismiss",
                 hint="Dismiss once you have seen them; only newer crashes will show. `coredumpctl list` shows when each happened.")


def c_plugin():
    built = ROOT / "build/qml/Caelestia"
    libs = list(built.rglob("*.so")) if built.is_dir() else []
    if not libs:
        return check("plugin", "Shell plugin build", "info", "No local build; using the system plugin")
    newest_lib = max(p.stat().st_mtime for p in libs)
    src = [p for p in (ROOT / "plugin/src").rglob("*") if p.suffix in (".cpp", ".hpp")]
    newest_src = max((p.stat().st_mtime for p in src), default=0)
    if newest_src > newest_lib + 1:
        return check("plugin", "Shell plugin build", "warn", "The C++ source is newer than the built plugin",
                     hint=f"cmake --build {ROOT}/build -j$(nproc), then restart the shell")
    return check("plugin", "Shell plugin build", "ok", "Up to date with the source")


def c_disk():
    st = os.statvfs(HOME)
    free = st.f_bavail / st.f_blocks
    gb = st.f_bavail * st.f_frsize / 2**30
    detail = f"{gb:.0f} GB free ({free * 100:.0f}%)"
    if free < 0.05:
        return check("disk", "Disk space", "bad", detail, hint="Low space breaks updates and caches")
    if free < 0.10:
        return check("disk", "Disk space", "warn", detail)
    return check("disk", "Disk space", "ok", detail)


CHECKS = [c_network, c_bluetooth, c_rfkill, c_btagent, c_shell_copies, c_wifi_dupes, c_polkit,
          c_portal, c_audio, c_monitors, c_crashes, c_plugin, c_disk]


# ---------------------------------------------------------------- fixes

def f_rfkill(_=None):
    ok = run("rfkill", "unblock", "wifi")[0] == 0 and run("rfkill", "unblock", "bluetooth")[0] == 0
    return ok, "Radios switched on" if ok else "rfkill refused; try the airplane-mode key"


def f_btagent(_=None):
    agents = bt_agents()
    for pid, _ in agents[1:]:
        try:
            os.kill(pid, 15)
        except OSError:
            pass
    return True, f"Stopped {max(len(agents) - 1, 0)} extra copies"


def f_forget(uuid):
    # Only profiles the check itself lists as leftovers can be removed, by exact UUID
    found, _ = wifi_dupes()
    if not found or uuid not in [u for u, _, _ in found]:
        return False, "That profile is no longer listed as a duplicate, so it was left alone"
    ok = run("nmcli", "connection", "delete", "uuid", uuid)[0] == 0
    return ok, "Forgot the profile" if ok else "NetworkManager refused to delete it"


def f_keep(uuid):
    found, _ = wifi_dupes()
    if not found or uuid not in [u for u, _, _ in found]:
        return False, "That profile is not listed any more"
    KEPT.parent.mkdir(parents=True, exist_ok=True)
    KEPT.write_text(json.dumps(sorted(kept_profiles() | {uuid})))
    return True, "Kept; it will not be listed again"


def f_polkit(_=None):
    if not os.access(POLKIT_AGENT, os.X_OK):
        return False, "The agent is not installed"
    subprocess.Popen([POLKIT_AGENT], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    time.sleep(1.5)
    ok = bool(procs(lambda a: os.path.basename(a[0]) == "polkit-gnome-authentication-agent-1"))
    return ok, "Agent started" if ok else "It exited right away; run it in a terminal to see why"


def f_crashes(_=None):
    DISMISS.parent.mkdir(parents=True, exist_ok=True)
    DISMISS.write_text(str(time.time()))
    return True, "Crashes dismissed"


def f_units(*units):
    def go(_=None):
        ok = run("systemctl", "--user", "restart", *units, timeout=20)[0] == 0
        return ok, "Restarted" if ok else "Restart failed"
    return go


FIXES = {"rfkill": f_rfkill, "btagent": f_btagent, "forget": f_forget, "keep": f_keep, "polkit": f_polkit, "crashes": f_crashes,
         "portal": f_units("xdg-desktop-portal-hyprland", "xdg-desktop-portal"),
         "audio": f_units("pipewire", "wireplumber")}


# Left out of background runs: they only matter when you are looking, and they cost the most
NOT_WATCHED = {c_wifi_dupes, c_plugin}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "check":
        res = []
        for fn in CHECKS:
            if "--watch" in sys.argv and fn in NOT_WATCHED:
                continue
            try:
                res.append(fn())
            except Exception as e:  # one broken check must not hide the rest
                res.append(check(fn.__name__[2:], fn.__name__[2:], "info", f"Check failed: {e}"))
        print(json.dumps(res))
    elif cmd == "fix" and len(sys.argv) > 2 and sys.argv[2] in FIXES:
        ok, msg = FIXES[sys.argv[2]](sys.argv[3] if len(sys.argv) > 3 else None)
        print(json.dumps({"ok": ok, "message": msg}))
    else:
        sys.exit("usage: doctor.py check | fix <id> [arg]")


if __name__ == "__main__":
    main()
