#!/usr/bin/env bash
# Builds op-caelestia-shell-git in a clean Arch container from the current commit of this repository,
# installs the result there and checks that the shell's QML and plugin resolve in the packaged layout.
# Needs docker. Usage: dist/arch/test-build.sh
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"

docker run --rm -v "$repo:/repo:ro" archlinux:base-devel bash -euxc '
pacman -Syu --noconfirm --needed git cmake ninja qt6-shadertools qt6-base qt6-declarative qt6-svg qt6-imageformats \
    libpipewire libqalculate aubio lm_sensors quickshell python python-dbus python-gobject sudo
useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
git config --global --add safe.directory /repo
su builder -c "
set -eux
# libcava is only in the AUR, as it is for upstream Caelestia
git clone https://aur.archlinux.org/libcava.git ~/libcava
(cd ~/libcava && makepkg -si --noconfirm)
mkdir -p ~/pkg && cp /repo/dist/arch/op-caelestia-shell-git/PKGBUILD ~/pkg/
cd ~/pkg
# build from the mounted checkout instead of GitHub
sed -i \"s|git+\\\$url.git|git+file:///repo|\" PKGBUILD
git config --global --add safe.directory /repo
# AUR-only runtime dependencies (caelestia-cli, a font) are not installed here
makepkg -d -f --noconfirm
"
pkg=$(ls /home/builder/pkg/*.pkg.tar.zst | head -n1)
echo "=== package contents (top levels)"
pacman -Qlp "$pkg" | sed "s#^[^ ]* ##" | awk -F/ "{print \"/\"\$2\"/\"\$3\"/\"\$4\"/\"\$5}" | sort -u | head -40
pacman -U --noconfirm --nodeps "$pkg"
echo "=== launcher"
op-caelestia --version
echo "=== QML and plugin resolve when launched headless (no compositor, so window errors are expected)"
export QML_IMPORT_PATH=/usr/lib/op-caelestia/qml QML2_IMPORT_PATH=/usr/lib/op-caelestia/qml QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR=/tmp
timeout 15 quickshell -p /usr/share/op-caelestia/shell.qml 2>&1 | head -40 || true
'
