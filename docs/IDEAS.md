# Ideas parked for later

Ideas we talked through and chose not to build yet. Each keeps enough detail to restart.

## Media stays solid inside see-through windows (2026-10-24)

**Idea**: apps look good slightly see-through, but video or images get damaged by it. Detect where the media sits in a window and keep only that area opaque, leaving the rest see-through.

**Why it's hard**: Hyprland opacity is per window, not per region. A window has `opacity` and an `opaque` flag; there is no per-window shader (only the global `decoration:screen_shader`). Checked on Hyprland 0.56.2.

**Ways to do it**

| | Approach | Result | Cost and risk |
|---|---|---|---|
| A | Media-aware solid windows: the whole window turns opaque while it shows media (media apps like mpv and imv, fullscreen, picture-in-picture, browser tabs seen playing video through MPRIS or the title), with a short fade | Whole window, not per region | Cheap and reliable. The browser case is the weak one: MPRIS says a browser plays video, not which window or area |
| B | Overlay patch: the shell watches the window, finds the region that changes like video, and draws it opaque in a transparent layer above the window | Per region | Heavy: continuous capture costs power and heat; region detection by pixels is fragile. Prototype first and measure battery cost |
| C | Browser extension reports `<video>`/image rectangles to the shell, which places opaque patches | Exact, per region | Much work; only browsers with the extension installed |

**Recommendation at the time**: build A first (as "Keep media solid" in Look & feel > Glass, with an editable list of what counts as media), prototype B only to measure its cost, C only if A isn't enough.

**Open question**: is a whole browser window turning solid while video plays good enough, or must it be only the video?
