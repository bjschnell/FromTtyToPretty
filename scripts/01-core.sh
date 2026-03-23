#!/usr/bin/env bash
# ============================================================================
# 01-core.sh — Core packages: ghostty, brave, neovim (lazyvim), tailscale
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
require_paru

# ── Packages ─────────────────────────────────────────────────────────────────

# Pacman repos
PACMAN_PKGS=(
    neovim
    tailscale
    git
    curl
    wget
    unzip
    ripgrep          # lazyvim dependency
    fd               # lazyvim dependency
    lazygit          # lazyvim optional (nice to have)
    wl-clipboard     # neovim clipboard on wayland
)

# AUR
AUR_PKGS=(
    ghostty
    brave-bin
)

# ── Install ──────────────────────────────────────────────────────────────────

info "Installing core pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

info "Installing AUR packages..."
paru -S --needed --noconfirm "${AUR_PKGS[@]}"

# ── Tailscale ────────────────────────────────────────────────────────────────

info "Enabling tailscaled service..."
sudo systemctl enable --now tailscaled

if ! tailscale status &>/dev/null; then
    warn "Tailscale is running but not authenticated."
    warn "Run: sudo tailscale up"
fi

# ── LazyVim ──────────────────────────────────────────────────────────────────

NVIM_CONFIG="$HOME/.config/nvim"

if [[ -d "$NVIM_CONFIG" ]]; then
    warn "Neovim config already exists at $NVIM_CONFIG — skipping LazyVim clone."
    warn "If you want a fresh LazyVim install, back up and remove that directory first."
else
    info "Bootstrapping LazyVim..."

    # Back up any existing state (shouldn't exist but be safe)
    for dir in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        [[ -d "$dir" ]] && mv "$dir" "${dir}.bak.$(date +%s)"
    done

    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"

    # Remove the starter's .git so you can track your own config
    rm -rf "$NVIM_CONFIG/.git"

    log "LazyVim bootstrapped. First launch of nvim will install plugins."
fi

log "Core packages installed"
