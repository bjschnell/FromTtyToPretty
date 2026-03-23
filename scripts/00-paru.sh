#!/usr/bin/env bash
# ============================================================================
# 00-paru.sh — Install paru (AUR helper)
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

if command -v paru &>/dev/null; then
    log "paru is already installed ($(paru --version | head -1))"
    exit 0
fi

info "Installing paru from source..."

# Ensure base-devel and git are present
sudo pacman -S --needed --noconfirm base-devel git

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

git clone https://aur.archlinux.org/paru.git "$TMPDIR/paru"
cd "$TMPDIR/paru"
makepkg -si --noconfirm

log "paru installed successfully"
