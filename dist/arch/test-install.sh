#!/usr/bin/env bash
# End-to-end test of install.sh in a clean Arch container, from the current commit of this repository:
# install (with a sample Hyprland config), check the result, then uninstall and check the config is
# byte-for-byte what it was. The two AUR packages that are heavy to build (caelestia-cli and a font) are
# replaced by empty stand-ins; libcava is built from the AUR for real. Needs docker.
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"

docker run --rm -v "$repo:/repo:ro" archlinux:base-devel bash -euxc '
pacman -Syu --noconfirm --needed git sudo curl
useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
su builder -c "
set -eux
git config --global --add safe.directory /repo
mkdir -p ~/standins && cd ~/standins
for name in caelestia-cli ttf-rubik-vf; do
    mkdir \$name && (cd \$name && printf \"pkgname=%s\npkgver=1\npkgrel=1\narch=(any)\npackage() { :; }\n\" \$name > PKGBUILD && makepkg -si --noconfirm)
done
git clone https://aur.archlinux.org/libcava.git ~/libcava && (cd ~/libcava && makepkg -si --noconfirm)

# a copy of the repository whose package builds from this checkout instead of GitHub
git clone /repo ~/op && cd ~/op
sed -i \"s|git+\\\$url.git|git+file:///repo|\" dist/arch/op-caelestia-shell-git/PKGBUILD

# a sample user config with a bind of its own
mkdir -p ~/.config/hypr
printf \"hl.config({})\nhl.bind(\\\"SUPER + Tab\\\", hl.dsp.exec_cmd(\\\"true\\\"))\n\" > ~/.config/hypr/hyprland.lua
cp ~/.config/hypr/hyprland.lua ~/hyprland.lua.original

echo \"=== INSTALL\"
./install.sh --yes --keybinds
echo \"=== CHECKS\"
test -x /usr/bin/op-caelestia
pacman -Qq op-caelestia-shell-git
op-caelestia config status
grep -c \">>> op-caelestia\" ~/.config/hypr/hyprland.lua
grep \"Super\\|SUPER + Tab\" ~/.config/hypr/op-caelestia.lua && exit 1 || echo \"existing SUPER+Tab bind was not overridden: ok\"
cat ~/.config/hypr/op-caelestia.lua

echo \"=== UNINSTALL\"
./install.sh --uninstall --yes
! pacman -Qq op-caelestia-shell-git
diff ~/hyprland.lua.original ~/.config/hypr/hyprland.lua && echo \"config byte-identical after uninstall: ok\"
test ! -e ~/.config/hypr/op-caelestia.lua
echo ALL-OK
"
'
