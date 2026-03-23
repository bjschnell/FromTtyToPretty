#!/usr/bin/env bash
# ============================================================================
# 05-dotfiles.sh — Dotfiles management via git bare repo
#
# This uses the bare repo pattern:
#   - A bare git repo lives at ~/.dotfiles
#   - Work tree is $HOME
#   - An alias 'dotfiles' replaces 'git' for dotfile operations
#
# Usage after setup:
#   dotfiles add ~/.config/hypr/hyprland.conf
#   dotfiles commit -m "hyprland config"
#   dotfiles push
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REMOTE=""  # ← SET THIS to your repo URL if you have one

# ── Alias helper ─────────────────────────────────────────────────────────────

ALIAS_CMD='alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"'

inject_alias() {
    local rc="$1"
    if [[ -f "$rc" ]] && ! grep -q 'alias dotfiles=' "$rc"; then
        echo "" >> "$rc"
        echo "# Dotfiles bare repo alias" >> "$rc"
        echo "$ALIAS_CMD" >> "$rc"
        info "Added dotfiles alias to $rc"
    fi
}

# ── Clone existing repo ─────────────────────────────────────────────────────

clone_existing() {
    local remote="$1"
    info "Cloning dotfiles from $remote ..."

    git clone --bare "$remote" "$DOTFILES_DIR"

    # Try checkout — if conflicts, back them up
    if ! git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>/dev/null; then
        warn "Checkout conflict — backing up existing files..."

        BACKUP_DIR="$HOME/.dotfiles-backup.$(date +%s)"
        mkdir -p "$BACKUP_DIR"

        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>&1 \
            | grep -E "^\s+" \
            | awk '{print $1}' \
            | while read -r file; do
                mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                mv "$HOME/$file" "$BACKUP_DIR/$file"
                warn "  Backed up: $file → $BACKUP_DIR/$file"
            done

        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout
    fi

    # Don't show untracked files (you don't want all of $HOME in status)
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

    log "Dotfiles cloned and checked out"
}

# ── Init fresh repo ─────────────────────────────────────────────────────────

init_fresh() {
    info "Initializing fresh dotfiles bare repo..."

    git init --bare "$DOTFILES_DIR"
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

    log "Fresh dotfiles repo initialized at $DOTFILES_DIR"
    echo ""
    info "Next steps:"
    echo "  1. Set your remote:"
    echo '     dotfiles remote add origin git@github.com:YOU/dotfiles.git'
    echo ""
    echo "  2. Start tracking files:"
    echo '     dotfiles add ~/.config/hypr/hyprland.conf'
    echo '     dotfiles add ~/.config/waybar/'
    echo '     dotfiles add ~/.config/ghostty/config'
    echo '     dotfiles commit -m "initial dotfiles"'
    echo '     dotfiles push -u origin main'
}

# ── Main ─────────────────────────────────────────────────────────────────────

if [[ -d "$DOTFILES_DIR" ]]; then
    log "Dotfiles repo already exists at $DOTFILES_DIR"
else
    if [[ -n "$DOTFILES_REMOTE" ]]; then
        clone_existing "$DOTFILES_REMOTE"
    else
        warn "No DOTFILES_REMOTE set in this script."
        echo ""
        read -rp "  Enter your dotfiles repo URL (or press Enter to init fresh): " remote

        if [[ -n "$remote" ]]; then
            clone_existing "$remote"
        else
            init_fresh
        fi
    fi
fi

# Inject alias into shell rc files
inject_alias "$HOME/.bashrc"
inject_alias "$HOME/.zshrc"

echo ""
log "Dotfiles setup complete"
info "Restart your shell or run:"
echo "  $ALIAS_CMD"
