#!/usr/bin/env bash
# ============================================================================
# 04-homelab.sh — Homelab / sysadmin essentials
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
require_paru

PACMAN_PKGS=(
    btop              # system monitor
    ncdu              # disk usage analyzer
    tree              # directory viewer
    lsof              # open file inspector
    iftop             # network bandwidth monitor
    nmap              # network scanner
    dnsutils          # dig, nslookup
    whois
    rsync
    tmux
    jq                # JSON processor
    yq                # YAML processor
    htop              # classic fallback
    bat               # cat with syntax highlighting
    eza               # modern ls (replaces exa)
    fzf               # fuzzy finder
    zoxide            # smarter cd
    ssh               # openssh
    ethtool
    traceroute
    net-tools         # ifconfig, netstat (legacy but useful)
)

AUR_PKGS=(
    lazydocker        # TUI for docker management
    duf               # disk usage (prettier df)
)

info "Installing homelab packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

info "Installing AUR homelab packages..."
paru -S --needed --noconfirm "${AUR_PKGS[@]}"

# ── Shell niceties ───────────────────────────────────────────────────────────
# These are suggestions — your dotfiles will likely override .bashrc/.zshrc

info "Shell integration hints:"
echo ""
echo "  # Add to your shell rc:"
echo '  eval "$(zoxide init bash)"     # or zsh'
echo '  alias ls="eza --icons"'
echo '  alias ll="eza -la --icons --git"'
echo '  alias cat="bat --paging=never"'
echo '  alias dc="docker compose"'
echo '  alias lg="lazygit"'
echo '  alias ld="lazydocker"'
echo ""

log "Homelab essentials installed"
