#!/usr/bin/env bash
# ============================================================================
# 03-docker.sh — Docker + docker-compose
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

PKGS=(
    docker
    docker-compose
    docker-buildx
)

info "Installing Docker..."
sudo pacman -S --needed --noconfirm "${PKGS[@]}"

# ── Service ──────────────────────────────────────────────────────────────────

info "Enabling Docker daemon..."
sudo systemctl enable --now docker

# ── Rootless access ──────────────────────────────────────────────────────────

if groups "$USER" | grep -qw docker; then
    log "User $USER is already in the docker group"
else
    info "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    warn "You'll need to log out and back in (or 'newgrp docker') for group changes to take effect."
fi

# ── Verify ───────────────────────────────────────────────────────────────────

info "Docker version:"
docker --version
info "Docker Compose version:"
docker compose version

log "Docker setup complete"
