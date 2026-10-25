#!/usr/bin/env bash
# Generates the bundled "Nebula" theme from scratch with ImageMagick, so it is original work that
# ships under the repository's own licence (GPL-3.0) and needs no third-party artwork.
# Usage: scripts/gen-default-theme.sh   (rewrites assets/themes/Nebula)
set -euo pipefail

out="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)/assets/themes/Nebula"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"

# Two soft clouds, a deep violet one and a teal-magenta one, blended
cloud() { # seed, dark, light, size
    magick -seed "$1" -size "$4" plasma:fractal -blur 0x40 -colorspace Gray -auto-level \
        -sigmoidal-contrast 4,50% +level-colors "$2,$3" "$tmp/c$1.png"
}
cloud 11 '#080818' '#7c4dff' 3840x2160
cloud 23 '#000000' '#ff4fa3' 3840x2160
magick "$tmp/c11.png" \( "$tmp/c23.png" -evaluate multiply 0.55 \) -compose screen -composite \
    -modulate 100,115 -quality 90 "$out/wallpaper.jpg"

# Looping artwork: a clouded orb that turns once, so the loop has no seam
orb() { # name, pixels, frames, colours
    local name=$1 px=$2 frames=$3 colours=$4 half=$(($2 / 2)) i
    magick "$out/wallpaper.jpg" -gravity center -crop "2160x2160+0+0" +repage -resize "$((px * 3 / 2))x$((px * 3 / 2))" "$tmp/$name-src.png"
    mkdir -p "$tmp/$name"
    for ((i = 0; i < frames; i++)); do
        magick "$tmp/$name-src.png" -distort SRT "$((i * 360 / frames))" -gravity center -crop "${px}x${px}+0+0" +repage \
            \( -size "${px}x${px}" xc:black -fill white -draw "circle $half,$half $half,2" \) \
            -alpha off -compose copy_opacity -composite "$tmp/$name/$(printf '%03d' "$i").png"
    done
    magick -delay 6 -loop 0 "$tmp/$name"/*.png -dispose background -colors "$colours" -layers optimize "$out/$name.gif"
}
orb lock 480 24 96
orb media 320 24 96
orb session 200 18 64

# Notification background: the same clouds, soft and wide
magick "$tmp/c11.png" -gravity center -crop 1000x932+0+0 +repage -resize 500x466 -blur 0x2 "$out/notif.png"

du -sh "$out"/* | sed "s#$out/##"
