#!/usr/bin/env bash
# ============================================================================
# lib/common.sh — Shared helpers for all bootstrap scripts
# Source this at the top of every script.
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

require_paru() {
    if ! command -v paru &>/dev/null; then
        err "paru is not installed. Run 00-paru.sh first."
    fi
}
