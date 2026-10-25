#!/usr/bin/env bash
# OP-Caelestia Shell installer for Arch-based systems (Arch, CachyOS, EndeavourOS).
#
# It builds and installs the shell as a real pacman package (so `pacman -R` removes it cleanly),
# installs the AUR packages it needs, and optionally sets up Hyprland: autostart and keybinds,
# with a backup and a one-command undo. It never rewrites your Hyprland config.
#
#   ./install.sh                 install (asks before every step)
#   ./install.sh --dry-run       show what would happen, change nothing
#   ./install.sh --uninstall     undo the Hyprland setup and remove the package
#
# Options: -y/--yes  answer yes to everything   --keybinds  also add suggested keybinds
#          --no-hyprland  leave the Hyprland config alone   --release  build the latest tagged release
#          (the default is the latest commit of main until the first release is tagged)
set -euo pipefail

REPO_URL="https://github.com/OVERxPOWERED/op-caelestia-shell.git"
AUR_DEPS=(caelestia-cli libcava ttf-rubik-vf)

YES=false DRY=false UNINSTALL=false KEYBINDS=false HYPR=true PKG=op-caelestia-shell-git
for arg in "$@"; do
    case "$arg" in
        -y|--yes) YES=true ;;
        --dry-run) DRY=true ;;
        --uninstall) UNINSTALL=true ;;
        --keybinds) KEYBINDS=true ;;
        --no-hyprland) HYPR=false ;;
        --release) PKG=op-caelestia-shell ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

if [[ -t 1 ]]; then B=$'\033[1m' G=$'\033[32m' Y=$'\033[33m' R=$'\033[31m' N=$'\033[0m'; else B="" G="" Y="" R="" N=""; fi
info() { echo "${B}==>${N} $*"; }
ok()   { echo "${G}ok${N}  $*"; }
warn() { echo "${Y}warn${N} $*" >&2; }
die()  { echo "${R}error${N} $*" >&2; exit 1; }

# Run a command, or only print it in a dry run
run() {
    if $DRY; then echo "    [dry run] $*"; return 0; fi
    "$@"
}

ask() { # question, default (Y or N)
    local def="${2:-Y}" reply
    $YES && return 0
    if [[ ! -t 0 ]]; then [[ "$def" == Y ]]; return; fi
    read -r -p "$1 [$([[ $def == Y ]] && echo Y/n || echo y/N)] " reply
    reply="${reply:-$def}"
    [[ "$reply" =~ ^[Yy] ]]
}

installed_pkg() { pacman -Qq op-caelestia-shell 2>/dev/null || pacman -Qq op-caelestia-shell-git 2>/dev/null || true; }

# ---------------------------------------------------------------- uninstall
if $UNINSTALL; then
    info "Undoing the Hyprland setup"
    if [[ -x /usr/bin/op-caelestia ]]; then run /usr/bin/op-caelestia config restore; else warn "op-caelestia is not installed; skipping the Hyprland undo"; fi
    pkg="$(installed_pkg)"
    if [[ -n "$pkg" ]]; then
        if ask "Remove the package $pkg?" Y; then run sudo pacman -Rns "$pkg"; fi
    else
        echo "No OP-Caelestia package is installed."
    fi
    echo
    echo "Your settings in ~/.config/caelestia and your notes were left alone. Delete them yourself if you want them gone."
    exit 0
fi

# ---------------------------------------------------------------- preflight
info "Checking your system"
[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root (makepkg refuses to run as root; sudo is used where needed)."

# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || true
case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*) ok "Arch-based system (${PRETTY_NAME:-$ID})" ;;
    *) die "This installer is for Arch-based systems (Arch, CachyOS, EndeavourOS). Found: ${PRETTY_NAME:-unknown}." ;;
esac

for cmd in pacman git sudo makepkg; do
    command -v "$cmd" >/dev/null || die "$cmd is missing. Install it first: sudo pacman -S --needed base-devel git sudo"
done
ok "pacman, git, sudo and makepkg are available"

if curl -fsI --max-time 10 https://github.com >/dev/null 2>&1; then ok "GitHub is reachable"; else warn "Could not reach github.com; the download will fail if you are offline."; fi

free_mb=$(df -Pm "${TMPDIR:-/tmp}" "$HOME" | awk 'NR>1{print $4}' | sort -n | head -n1)
(( free_mb >= 2048 )) || warn "Only ${free_mb} MB free; building needs about 2 GB."

if command -v Hyprland >/dev/null; then
    ok "Hyprland $(Hyprland --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n1) found"
else
    warn "Hyprland is not installed; it is installed as a dependency of the shell."
fi
if pacman -Qq caelestia-shell >/dev/null 2>&1; then ok "Vanilla Caelestia is installed; OP-Caelestia runs next to it without touching it"; fi

have_pkg="$(installed_pkg)"
if [[ -n "$have_pkg" ]]; then ok "$have_pkg is installed; this will update it"; fi

# An earlier version of this installer put its own launcher in ~/.local/bin, which comes first in PATH
# and would shadow the packaged /usr/bin/op-caelestia
old_launcher="$HOME/.local/bin/op-caelestia"
if [[ -e "$old_launcher" ]] && ! pacman -Qo "$old_launcher" >/dev/null 2>&1; then
    warn "$old_launcher is a launcher from an older installer and would hide the new one."
    if ask "Move it aside (to op-caelestia.old)?" Y; then run mv "$old_launcher" "$old_launcher.old"; fi
fi

# ---------------------------------------------------------------- plan
helper=""
for h in paru yay; do
    if command -v "$h" >/dev/null; then helper="$h"; break; fi
done
mapfile -t missing_aur < <(pacman -T "${AUR_DEPS[@]}" || true)

echo
info "Plan"
echo "  1. AUR packages needed: ${missing_aur[*]:-none missing}"
if ((${#missing_aur[@]})); then
    if [[ -n "$helper" ]]; then echo "     installed with $helper"; else echo "     no AUR helper found: paru-bin would be installed first, with makepkg"; fi
fi
echo "  2. Build and install $PKG with makepkg (a few minutes; official dependencies come from pacman, with sudo)"
if $HYPR; then
    echo "  3. Hyprland setup: autostart and, if you want them, keybinds; shown in full and confirmed first, with a backup and a one-command undo"
else
    echo "  3. Hyprland config: left alone (--no-hyprland)"
fi
echo
ask "Continue?" Y || { echo "Nothing changed."; exit 0; }

# ---------------------------------------------------------------- AUR packages
if ((${#missing_aur[@]})); then
    if [[ -z "$helper" ]]; then
        ask "Install the AUR helper paru-bin now (built with makepkg)?" Y || die "Install an AUR helper (paru or yay), or the packages ${missing_aur[*]} by hand, then run this again."
        work="$(mktemp -d)"
        run git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$work/paru-bin"
        $DRY || (cd "$work/paru-bin" && makepkg -si --needed)
        helper=paru
    fi
    info "Installing the AUR packages: ${missing_aur[*]}"
    run "$helper" -S --needed --asdeps "${missing_aur[@]}"
fi

# ---------------------------------------------------------------- the package
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P || true)"
if [[ -n "$here" && -d "$here/dist/arch/$PKG" ]]; then
    src="$here"
else
    src="${XDG_CACHE_HOME:-$HOME/.cache}/op-caelestia/src"
    info "Fetching the sources into $src"
    if [[ -d "$src/.git" ]]; then run git -C "$src" pull --ff-only; else run git clone --depth 1 "$REPO_URL" "$src"; fi
fi

info "Building $PKG (this compiles the C++ plugin; a few minutes)"
makeflags=(-si --needed)
$YES && makeflags+=(--noconfirm)
if $DRY; then
    echo "    [dry run] cd $src/dist/arch/$PKG && makepkg ${makeflags[*]}"
else
    (cd "$src/dist/arch/$PKG" && makepkg "${makeflags[@]}")
fi

# ---------------------------------------------------------------- Hyprland
if $HYPR; then
    echo
    info "Hyprland setup"
    if $DRY; then
        echo "    [dry run] op-caelestia config plan, then apply if you agree"
    elif ask "Look at what would be added to your Hyprland config, and apply it if you agree?" Y; then
        args=()
        if $KEYBINDS; then
            args+=(--keybinds)
        elif ask "Also add suggested keybinds (Super+Space launcher, Super+Tab overview, Super+I settings, ...)? Keys you already use are never overridden." N; then
            args+=(--keybinds)
        fi
        $YES && args+=(--yes)
        /usr/bin/op-caelestia config apply "${args[@]}" || warn "The Hyprland setup was not applied; run \`op-caelestia config apply\` later."
    fi
fi

echo
echo "${G}${B}Done.${N}"
echo "  Start the shell:   op-caelestia           (or log out and back in if Hyprland starts it)"
echo "  Undo the Hyprland setup:   op-caelestia config restore"
echo "  Uninstall:         ./install.sh --uninstall"
echo "  Something wrong?   open Nexus > Doctor, or see docs/installation.md"
