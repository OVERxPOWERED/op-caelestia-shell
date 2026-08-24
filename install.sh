#!/usr/bin/env bash
# ==============================================================================
#  🌌 OP-Caelestia Shell - Automated Installer & Side-by-Side Setup Script
#  Repository: https://github.com/OVERxPOWERED/op-caelestia-shell
# ==============================================================================

set -euo pipefail

# ANSI Colors
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_CYAN="\033[38;2;128;202;255m"
CLR_PURPLE="\033[38;2;195;160;255m"
CLR_GREEN="\033[38;2;74;222;128m"
CLR_YELLOW="\033[38;2;250;204;21m"
CLR_RED="\033[38;2;248;113;113m"
CLR_MUTED="\033[38;2;148;163;184m"

# Flags
NON_INTERACTIVE=false
for arg in "$@"; do
    case "$arg" in
        -y|--yes|--noconfirm) NON_INTERACTIVE=true ;;
    esac
done

print_banner() {
    echo -e "${CLR_CYAN}${CLR_BOLD}"
    cat << "EOF"
   ____  ____        ______           __          __  _       
  / __ \/ __ \      / ____/___ _____ / /__  _____/ /_(_)___ _
 / / / / /_/ /_____/ /   / __ `/ __ / / _ \/ ___/ __/ / __ `/
/ /_/ / ____/_____/ /___/ /_/ / /_/ / /  __(__  ) /_/ / /_/ / 
\____/_/          \____/\__,_/\__,_/_/\___/____/\__/_/\__,_/  
                    Enhanced Desktop Shell for Hyprland
EOF
    echo -e "${CLR_RESET}"
}

log_info() {
    echo -e "${CLR_CYAN}[INFO]${CLR_RESET} $1"
}

log_success() {
    echo -e "${CLR_GREEN}[SUCCESS]${CLR_RESET} $1"
}

log_warn() {
    echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $1"
}

log_error() {
    echo -e "${CLR_RED}[ERROR]${CLR_RESET} $1"
}

ask_prompt() {
    local prompt_text="$1"
    local default_ans="${2:-Y}"
    if [ "$NON_INTERACTIVE" = true ]; then
        return 0
    fi
    local answer
    if [ -t 0 ]; then
        read -rp "$(echo -e "${CLR_PURPLE}?${CLR_RESET} ${CLR_BOLD}${prompt_text}${CLR_RESET} [${default_ans}]: ")" answer
    elif [ -e /dev/tty ]; then
        read -rp "$(echo -e "${CLR_PURPLE}?${CLR_RESET} ${CLR_BOLD}${prompt_text}${CLR_RESET} [${default_ans}]: ")" answer </dev/tty
    else
        return 0
    fi
    answer="${answer:-$default_ans}"
    case "$answer" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

print_banner

# 1. Target Directory Resolution (Zero Conflicts with Existing Caelestia)
CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
REPO_URL="https://github.com/OVERxPOWERED/op-caelestia-shell.git"
CURRENT_DIR="$(pwd -P 2>/dev/null || echo "")"

if [ -f "$CURRENT_DIR/shell.qml" ] && [ -f "$CURRENT_DIR/CMakeLists.txt" ]; then
    # Running directly from a cloned working directory
    TARGET_DIR="$CURRENT_DIR"
    log_info "Running setup inside current repository: $TARGET_DIR"
else
    # Check if vanilla caelestia folder already exists
    if [ -d "$CONFIG_BASE/quickshell/caelestia" ]; then
        TARGET_DIR="$CONFIG_BASE/quickshell/op-caelestia"
        log_info "Detected existing Caelestia folder at $CONFIG_BASE/quickshell/caelestia."
        log_info "Installing OP-Caelestia side-by-side to $TARGET_DIR (no files overwritten)."
    else
        TARGET_DIR="$CONFIG_BASE/quickshell/caelestia"
        log_info "Target destination: $TARGET_DIR"
    fi
fi

# 2. Clone or Sync Repository
if [ "$CURRENT_DIR" != "$TARGET_DIR" ]; then
    if [ -d "$TARGET_DIR/.git" ]; then
        log_info "Existing installation detected in $TARGET_DIR. Updating to latest commit..."
        git -C "$TARGET_DIR" pull --ff-only || log_warn "Could not fast-forward existing repo. Continuing with current files..."
    elif [ -d "$TARGET_DIR" ]; then
        log_warn "Directory $TARGET_DIR already exists."
        if ask_prompt "Overwrite and re-clone $TARGET_DIR?" "N"; then
            rm -rf "$TARGET_DIR"
            mkdir -p "$CONFIG_BASE/quickshell"
            git clone "$REPO_URL" "$TARGET_DIR"
        fi
    else
        log_info "Cloning OP-Caelestia Shell into $TARGET_DIR..."
        mkdir -p "$CONFIG_BASE/quickshell"
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
    cd "$TARGET_DIR"
fi

# Ensure executable scripts
chmod +x "$TARGET_DIR/install.sh" "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true

# 3. Detect Package Manager & Check Dependencies
log_info "Checking dependencies..."

PKG_HELPER=""
if command -v paru >/dev/null 2>&1; then
    PKG_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    PKG_HELPER="yay"
elif command -v pacman >/dev/null 2>&1; then
    PKG_HELPER="pacman"
fi

REQUIRED_PACKAGES=(
    "cmake"
    "ninja"
    "gcc"
    "qt6-base"
    "qt6-declarative"
    "qt6-imageformats"
    "qt6-shadertools"
    "pipewire"
    "libpipewire"
    "libcava"
    "aubio"
    "ddcutil"
    "brightnessctl"
    "networkmanager"
    "power-profiles-daemon"
    "swappy"
    "lm_sensors"
    "libqalculate"
    "fish"
    "bash"
    "ttf-material-symbols-variable"
    "ttf-rubik-vf"
    "ttf-cascadia-code-nerd"
    "quickshell-git"
)

MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1 && ! pacman -Q "$pkg" >/dev/null 2>&1; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log_warn "Missing dependencies detected (${#MISSING_PACKAGES[@]} packages):"
    echo -e "${CLR_MUTED}${MISSING_PACKAGES[*]}${CLR_RESET}\n"

    if [ -n "$PKG_HELPER" ]; then
        if ask_prompt "Install missing packages automatically using $PKG_HELPER?" "Y"; then
            log_info "Installing missing dependencies..."
            if [ "$PKG_HELPER" = "pacman" ]; then
                sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
            else
                $PKG_HELPER -S --needed "${MISSING_PACKAGES[@]}"
            fi
            log_success "Dependencies installed successfully!"
        else
            log_warn "Skipping dependency installation. Note: Build may fail if core libraries are missing."
        fi
    else
        log_warn "No AUR helper (paru/yay) or pacman detected. Please install missing packages manually."
    fi
else
    log_success "All required dependencies are satisfied!"
fi

# 4. Build & Install Local Isolated C++ Plugin
log_info "Building native C++ Caelestia helper plugin..."
mkdir -p "$TARGET_DIR/build"
cd "$TARGET_DIR/build"

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/ \
    ..

cmake --build .

log_info "Deploying plugin locally (.local-caelestia-plugin)..."
DESTDIR="$TARGET_DIR/.local-caelestia-plugin" cmake --install .

cd "$TARGET_DIR"
log_success "Native C++ plugin built and deployed successfully!"

# 5. Configuration Directory Initialization
CONFIG_DIR="$CONFIG_BASE/caelestia"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/shell.json" ]; then
    log_info "Creating default starter configuration in $CONFIG_DIR/shell.json..."
    cat > "$CONFIG_DIR/shell.json" << 'EOF'
{
  "dock": {
    "enabled": true,
    "position": "bottom",
    "autoHide": false,
    "scale": 1.0,
    "pinnedApps": [
      "firefox.desktop",
      "kitty.desktop",
      "thunar.desktop",
      "spotify.desktop"
    ]
  },
  "overview": {
    "defaultTab": "carousel",
    "showSpecialWorkspaces": true,
    "scale": 1.0
  },
  "lock": {
    "patternEnabled": true,
    "patternConfirmation": true
  },
  "background": {
    "wallpaperEnabled": true
  }
}
EOF
    log_success "Created starter shell.json configuration!"
fi

# 6. Global Launcher Binary (~/.local/bin/op-caelestia)
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/op-caelestia" << EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "-k" || "\${1:-}" == "--kill" ]]; then
    killall -9 quickshell 2>/dev/null || true
    exit 0
elif [[ "\${1:-}" == "-r" || "\${1:-}" == "--restart" ]]; then
    killall -9 quickshell 2>/dev/null || true
    sleep 0.5
    exec "$TARGET_DIR/scripts/startup-shell.sh" -d -n
fi
exec "$TARGET_DIR/scripts/startup-shell.sh" -d -n "\$@"
EOF
chmod +x "$BIN_DIR/op-caelestia"
log_success "Created global launcher shortcut: op-caelestia (in ~/.local/bin/op-caelestia)"

# 7. Hyprland Autostart Integration (Intelligent Lua & Conf Detection)
log_info "Detecting Hyprland configuration format..."

AUTOSTART_TARGET_FILE=""
AUTOSTART_TYPE=""

# Priority 1: Check for Lua configurations (Caelestia dotfiles / Hyprland Lua)
if [ -f "$CONFIG_BASE/hypr/hyprland/execs.lua" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/hyprland/execs.lua"
    AUTOSTART_TYPE="lua"
elif [ -f "$CONFIG_BASE/hypr/execs.lua" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/execs.lua"
    AUTOSTART_TYPE="lua"
elif [ -f "$CONFIG_BASE/hypr/hyprland.lua" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/hyprland.lua"
    AUTOSTART_TYPE="lua"
# Priority 2: Check for Conf configurations (Standard Hyprland)
elif [ -f "$CONFIG_BASE/hypr/hyprland/execs.conf" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/hyprland/execs.conf"
    AUTOSTART_TYPE="conf"
elif [ -f "$CONFIG_BASE/hypr/execs.conf" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/execs.conf"
    AUTOSTART_TYPE="conf"
elif [ -f "$CONFIG_BASE/hypr/hyprland.conf" ]; then
    AUTOSTART_TARGET_FILE="$CONFIG_BASE/hypr/hyprland.conf"
    AUTOSTART_TYPE="conf"
fi

if [ -n "$AUTOSTART_TARGET_FILE" ]; then
    if ! grep -q "op-caelestia" "$AUTOSTART_TARGET_FILE" && ! grep -q "startup-shell.sh" "$AUTOSTART_TARGET_FILE"; then
        REL_PATH="${AUTOSTART_TARGET_FILE/#$HOME/~}"
        if ask_prompt "Add OP-Caelestia Shell autostart to $REL_PATH?" "Y"; then
            if [ "$AUTOSTART_TYPE" = "lua" ]; then
                echo "" >> "$AUTOSTART_TARGET_FILE"
                echo "-- Autostart OP-Caelestia Shell" >> "$AUTOSTART_TARGET_FILE"
                echo 'hl.exec_cmd("sleep 0.5 && op-caelestia")' >> "$AUTOSTART_TARGET_FILE"
            else
                echo "" >> "$AUTOSTART_TARGET_FILE"
                echo "# Autostart OP-Caelestia Shell" >> "$AUTOSTART_TARGET_FILE"
                echo "exec-once = op-caelestia" >> "$AUTOSTART_TARGET_FILE"
            fi
            log_success "Added autostart command to $REL_PATH ($AUTOSTART_TYPE format)"
        fi
    else
        log_info "Autostart entry already present in $AUTOSTART_TARGET_FILE."
    fi
else
    log_info "No existing Hyprland config found. You can add 'op-caelestia' to your autostart manually."
fi

# 8. Completion & Instructions
REL_TARGET="${AUTOSTART_TARGET_FILE/#$HOME/~}"

echo ""
echo -e "${CLR_GREEN}${CLR_BOLD}======================================================${CLR_RESET}"
echo -e "${CLR_GREEN}${CLR_BOLD} 🎉 OP-Caelestia Shell Installation Complete!${CLR_RESET}"
echo -e "${CLR_GREEN}${CLR_BOLD}======================================================${CLR_RESET}\n"

echo -e "${CLR_BOLD}🎮 CLI Management Commands:${CLR_RESET}"
echo -e "  • Start:    ${CLR_CYAN}op-caelestia${CLR_RESET}"
echo -e "  • Restart:  ${CLR_CYAN}op-caelestia -r${CLR_RESET}"
echo -e "  • Stop:     ${CLR_CYAN}op-caelestia -k${CLR_RESET}\n"

echo -e "${CLR_BOLD}⚡ Autostart & Switching Shells:${CLR_RESET}"
if [ -n "$AUTOSTART_TARGET_FILE" ]; then
    if [ "$AUTOSTART_TYPE" = "lua" ]; then
        echo -e "  • Autostart configured in: ${CLR_CYAN}$REL_TARGET${CLR_RESET}"
        echo -e "    Added line: ${CLR_MUTED}hl.exec_cmd(\"sleep 0.5 && op-caelestia\")${CLR_RESET}"
    else
        echo -e "  • Autostart configured in: ${CLR_CYAN}$REL_TARGET${CLR_RESET}"
        echo -e "    Added line: ${CLR_MUTED}exec-once = op-caelestia${CLR_RESET}"
    fi
    echo -e "  • ${CLR_YELLOW}To disable or change:${CLR_RESET} Open ${CLR_CYAN}$REL_TARGET${CLR_RESET} and comment out / remove the line."
    echo -e "  • ${CLR_YELLOW}To switch back to vanilla Caelestia:${CLR_RESET} Replace ${CLR_CYAN}op-caelestia${CLR_RESET} with ${CLR_CYAN}caelestia shell -d${CLR_RESET} in that file.\n"
else
    echo -e "  • To enable autostart on boot, add ${CLR_CYAN}exec-once = op-caelestia${CLR_RESET} to your Hyprland configuration.\n"
fi

if ask_prompt "Would you like to start OP-Caelestia Shell now?" "Y"; then
    log_info "Stopping any previous shell instances..."
    killall -9 quickshell 2>/dev/null || true
    sleep 0.5
    log_info "Launching OP-Caelestia Shell..."
    "$TARGET_DIR/scripts/startup-shell.sh" &
    disown
    log_success "OP-Caelestia Shell launched in background!"
fi
