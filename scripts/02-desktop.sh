#!/usr/bin/env bash
# ============================================================================
# 02-desktop.sh — Hyprland rice: waybar, wofi, dunst, swww, theming, etc.
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
require_paru

# ── Hyprland core ────────────────────────────────────────────────────────────

PACMAN_PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    qt5-wayland
    qt6-wayland

    # Bar / launcher / notifications
    waybar
    wofi
    dunst

    # Terminal / file manager
    thunar
    gvfs                      # thunar trash/mount support

    # Screenshots / screen recording
    grim
    slurp
    swappy                    # screenshot annotation

    # Clipboard
    wl-clipboard
    cliphist

    # Auth / polkit
    polkit-gnome

    # Audio
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts
    noto-fonts-emoji

    # Theming
    gtk3
    gtk4
    nwg-look                  # GTK theme picker for wayland

    # Misc
    brightnessctl
    playerctl
    network-manager-applet
    bluez
    bluez-utils
    blueman
)

AUR_PKGS=(
    swww                      # wallpaper daemon (animated)
    hyprlock                  # lock screen
    hypridle                  # idle daemon
    wlogout                   # logout menu
    rofi-lbonn-wayland-git    # if you prefer rofi over wofi
)

# ── Install ──────────────────────────────────────────────────────────────────

info "Installing Hyprland desktop packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

info "Installing AUR desktop packages..."
paru -S --needed --noconfirm "${AUR_PKGS[@]}"

# ── Services ─────────────────────────────────────────────────────────────────

info "Enabling Bluetooth..."
sudo systemctl enable --now bluetooth

info "Enabling PipeWire..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# ── Skeleton configs ─────────────────────────────────────────────────────────
# Only creates minimal stubs if no config exists yet.
# Your dotfiles script (05-dotfiles.sh) will overwrite these.

create_if_missing() {
    local path="$1"
    local content="$2"
    if [[ ! -f "$path" ]]; then
        mkdir -p "$(dirname "$path")"
        echo "$content" > "$path"
        info "Created skeleton: $path"
    else
        warn "Config exists, skipping: $path"
    fi
}

create_if_missing "$HOME/.config/hypr/hyprland.conf" \
'# Hyprland config stub — replace with your dotfiles
# See: https://wiki.hyprland.org/Configuring/

monitor=,preferred,auto,1

exec-once = waybar
exec-once = dunst
exec-once = swww-daemon
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(89b4fa) rgb(cba6f7) 45deg
    col.inactive_border = rgb(313244)
    layout = dwindle
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 5
        passes = 2
    }
}

animations {
    enabled = true
}

dwindle {
    pseudotile = true
    preserve_split = true
}

# Keybinds
$mod = SUPER
bind = $mod, Return, exec, ghostty
bind = $mod, Q, killactive
bind = $mod, D, exec, wofi --show drun
bind = $mod, E, exec, thunar
bind = $mod SHIFT, S, exec, grim -g "$(slurp)" - | swappy -f -
bind = $mod, L, exec, hyprlock
bind = $mod SHIFT, Q, exec, wlogout

# Move focus
bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d

# Workspaces
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

# Resize
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
'

log "Desktop environment setup complete"
info "If this is a fresh install, reboot or start Hyprland with: Hyprland"
