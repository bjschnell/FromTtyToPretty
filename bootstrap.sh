#!/usr/bin/env bash
# ============================================================================
# FromTtyToPretty — Arch Linux + Hyprland post-install bootstrap
#
# Usage:
#   ./bootstrap.sh                    Interactive profile picker
#   ./bootstrap.sh --profile full     Run a preset profile
#   ./bootstrap.sh --interactive      Ask per-script yes/no
#   ./bootstrap.sh --list             Show available profiles
#   ./bootstrap.sh --version          Show version
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# -- Colors ----------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
err()  { echo -e "${RED}[!!]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[..]${NC} $1"; }

# -- Version ---------------------------------------------------------------

get_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        tr -d '[:space:]' < "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

# -- Script registry -------------------------------------------------------
# Format: "filename:description:tags"
# Tags control which profiles include the script.

SCRIPTS=(
    "00-paru.sh:Install paru AUR helper:minimal,desktop,homelab,full"
    "01-core.sh:Core packages (ghostty, brave, nvim, tailscale):minimal,desktop,homelab,full"
    "02-desktop.sh:Hyprland rice (waybar, wofi, dunst, swww, etc.):desktop,full"
    "03-docker.sh:Docker + docker-compose:homelab,full"
    "04-homelab.sh:Homelab essentials (btop, ncdu, lazydocker, etc.):homelab,full"
    "05-dotfiles.sh:Dotfiles via git bare repo:minimal,desktop,homelab,full"
)

PROFILES=("minimal" "desktop" "homelab" "full")

# -- Helpers ----------------------------------------------------------------

get_script_name() { echo "${1%%:*}"; }
get_script_desc() { local tmp="${1#*:}"; echo "${tmp%%:*}"; }
get_script_tags() { echo "${1##*:}"; }

script_in_profile() {
    local tags="$1"
    local profile="$2"
    [[ ",$tags," == *",$profile,"* ]]
}

run_script() {
    local script="$1"
    local path="$SCRIPTS_DIR/$script"

    if [[ ! -f "$path" ]]; then
        err "Script not found: $path"
        return 1
    fi

    echo ""
    echo -e "${CYAN}================================================${NC}"
    info "Running ${BOLD}$script${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""

    bash "$path"

    echo ""
    log "Finished $script"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi

    while true; do
        read -rp "  $prompt" answer
        answer="${answer:-$default}"
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     echo "  Please answer y or n." ;;
        esac
    done
}

# -- Banner -----------------------------------------------------------------

show_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "   +-------------------------------------------+"
    echo "   |        FromTtyToPretty                     |"
    echo "   |      Arch + Hyprland post-install          |"
    echo "   +-------------------------------------------+"
    echo -e "${NC}"
    echo -e "  ${DIM}v$(get_version)${NC}"
    echo ""
}

# -- Profile display --------------------------------------------------------

show_profiles() {
    echo ""
    echo -e "  ${BOLD}Available profiles:${NC}"
    echo ""

    for profile in "${PROFILES[@]}"; do
        echo -e "  ${CYAN}${BOLD}$profile${NC}"

        for entry in "${SCRIPTS[@]}"; do
            local name desc tags
            name="$(get_script_name "$entry")"
            desc="$(get_script_desc "$entry")"
            tags="$(get_script_tags "$entry")"

            if script_in_profile "$tags" "$profile"; then
                echo -e "    ${GREEN}+${NC} $desc  ${DIM}($name)${NC}"
            else
                echo -e "    ${DIM}- $desc  ($name)${NC}"
            fi
        done
        echo ""
    done
}

# -- Run profile ------------------------------------------------------------

run_profile() {
    local profile="$1"

    info "Running profile: ${BOLD}$profile${NC}"
    echo ""

    echo -e "  ${BOLD}This will run:${NC}"
    for entry in "${SCRIPTS[@]}"; do
        local name desc tags
        name="$(get_script_name "$entry")"
        desc="$(get_script_desc "$entry")"
        tags="$(get_script_tags "$entry")"

        if script_in_profile "$tags" "$profile"; then
            echo -e "    ${GREEN}+${NC} $desc"
        fi
    done
    echo ""

    if ! ask_yes_no "Proceed?" "y"; then
        echo "  Aborted."
        exit 0
    fi

    local count=0
    local skipped=0

    for entry in "${SCRIPTS[@]}"; do
        local name desc tags
        name="$(get_script_name "$entry")"
        desc="$(get_script_desc "$entry")"
        tags="$(get_script_tags "$entry")"

        if script_in_profile "$tags" "$profile"; then
            run_script "$name"
            ((count++))
        else
            info "Skipping $desc ${DIM}(not in $profile profile)${NC}"
            ((skipped++))
        fi
    done

    echo ""
    log "Profile ${BOLD}$profile${NC} complete -- ran $count scripts, skipped $skipped"
}

# -- Interactive mode -------------------------------------------------------

run_interactive() {
    info "Interactive mode -- you'll be asked about each script."

    local ran=0
    local skipped=0

    for entry in "${SCRIPTS[@]}"; do
        local name desc
        name="$(get_script_name "$entry")"
        desc="$(get_script_desc "$entry")"

        echo ""
        echo -e "  ${BOLD}$desc${NC}"
        echo -e "  ${DIM}$name${NC}"

        if ask_yes_no "Run this?" "y"; then
            run_script "$name"
            ((ran++))
        else
            warn "Skipped $name"
            ((skipped++))
        fi
    done

    echo ""
    log "Done -- ran $ran scripts, skipped $skipped"
}

# -- Profile picker ---------------------------------------------------------

pick_profile() {
    echo -e "  ${BOLD}Pick a profile or go interactive:${NC}"
    echo ""
    echo "  [1] minimal     paru + core + dotfiles"
    echo "  [2] desktop     minimal + hyprland rice"
    echo "  [3] homelab     minimal + docker + homelab tools"
    echo "  [4] full        everything"
    echo ""
    echo "  [i] interactive -- choose per script"
    echo "  [l] list        -- show what's in each profile"
    echo "  [q] quit"
    echo ""

    while true; do
        read -rp "  Choose: " choice
        case "$choice" in
            1) run_profile "minimal"; return ;;
            2) run_profile "desktop"; return ;;
            3) run_profile "homelab"; return ;;
            4) run_profile "full"; return ;;
            i|I) run_interactive; return ;;
            l|L) show_profiles; pick_profile; return ;;
            q|Q) echo "  Bye!"; exit 0 ;;
            *)   echo "  Invalid selection, try again." ;;
        esac
    done
}

# -- Main -------------------------------------------------------------------

main() {
    case "${1:-}" in
        --version|-v|-V)
            echo "FromTtyToPretty v$(get_version)"
            exit 0
            ;;
        *) ;;
    esac

    show_banner

    case "${1:-}" in
        --profile|-p)
            local profile="${2:-}"
            if [[ -z "$profile" ]]; then
                err "Usage: ./bootstrap.sh --profile <minimal|desktop|homelab|full>"
            fi
            local valid=false
            for p in "${PROFILES[@]}"; do
                [[ "$p" == "$profile" ]] && valid=true
            done
            if ! $valid; then
                err "Unknown profile: $profile (available: ${PROFILES[*]})"
            fi
            run_profile "$profile"
            ;;
        --list|-l)
            show_profiles
            ;;
        --interactive|-i)
            run_interactive
            ;;
        --help|-h)
            echo "Usage:"
            echo "  ./bootstrap.sh                     Interactive profile picker"
            echo "  ./bootstrap.sh --profile <name>    Run a preset profile"
            echo "  ./bootstrap.sh --interactive       Ask per-script yes/no"
            echo "  ./bootstrap.sh --list              Show profiles and their scripts"
            echo "  ./bootstrap.sh --version           Show version"
            echo ""
            echo "Profiles: ${PROFILES[*]}"
            ;;
        "")
            pick_profile
            ;;
        *)
            err "Unknown option: $1 (try --help)"
            ;;
    esac
}

main "$@"
