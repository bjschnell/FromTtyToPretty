#!/usr/bin/env bash
# ============================================================================
# release.sh — Bump version, generate changelog, tag the release
#
# Usage:
#   ./release.sh patch    # 0.1.0 -> 0.1.1
#   ./release.sh minor    # 0.1.0 -> 0.2.0
#   ./release.sh major    # 0.1.0 -> 1.0.0
#
# Expects conventional commits:
#   feat: add nvidia script        -> Features
#   fix: correct paru clone url    -> Bug Fixes
#   docs: update README            -> Documentation
#   refactor: simplify profiles    -> Refactoring
#   chore: clean up temp files     -> Chores
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
CHANGELOG="$SCRIPT_DIR/CHANGELOG.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
err()  { echo -e "${RED}[!!]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[..]${NC} $1"; }

# -- Validate ---------------------------------------------------------------

BUMP_TYPE="${1:-}"

if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo "Usage: ./release.sh <patch|minor|major>"
    echo ""
    echo "  patch   0.1.0 -> 0.1.1   (bug fixes)"
    echo "  minor   0.1.0 -> 0.2.0   (new features)"
    echo "  major   0.1.0 -> 1.0.0   (breaking changes)"
    exit 1
fi

# Make sure we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    err "Not a git repository"
fi

# Make sure working tree is clean
if [[ -n "$(git status --porcelain)" ]]; then
    err "Working tree is dirty. Commit or stash changes first."
fi

# -- Read current version ---------------------------------------------------

if [[ ! -f "$VERSION_FILE" ]]; then
    err "VERSION file not found"
fi

CURRENT="$(tr -d '[:space:]' < "$VERSION_FILE")"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

info "Current version: ${CURRENT}"

# -- Bump -------------------------------------------------------------------

case "$BUMP_TYPE" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEW_VERSION}"

info "New version: ${NEW_VERSION} (${TAG})"

# Check tag doesn't already exist
if git tag -l "$TAG" | grep -q "$TAG"; then
    err "Tag $TAG already exists"
fi

# -- Generate changelog entry -----------------------------------------------

# Find the last tag, or use initial commit if no tags exist
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"

if [[ -n "$LAST_TAG" ]]; then
    RANGE="${LAST_TAG}..HEAD"
    info "Generating changelog from ${LAST_TAG} to HEAD"
else
    RANGE="HEAD"
    info "Generating changelog from all commits (first release)"
fi

# Collect commits by type
declare -A SECTIONS
SECTIONS=(
    [feat]="Features"
    [fix]="Bug Fixes"
    [docs]="Documentation"
    [refactor]="Refactoring"
    [perf]="Performance"
    [chore]="Chores"
)

ENTRY="## [${NEW_VERSION}] - $(date +%Y-%m-%d)"
ENTRY+="\n"

HAS_CONTENT=false

for type in feat fix docs refactor perf chore; do
    # Match "type: message" or "type(scope): message"
    COMMITS="$(git log "$RANGE" --pretty=format:'%s' 2>/dev/null \
        | grep -E "^${type}(\(.+\))?:" \
        | sed -E "s/^${type}(\(.+\))?:\s*//" \
        || true)"

    if [[ -n "$COMMITS" ]]; then
        HAS_CONTENT=true
        ENTRY+="\n### ${SECTIONS[$type]}\n"
        while IFS= read -r msg; do
            ENTRY+="- ${msg}\n"
        done <<< "$COMMITS"
    fi
done

# Catch any commits that don't follow conventional format
UNCONVENTIONAL="$(git log "$RANGE" --pretty=format:'%s' 2>/dev/null \
    | grep -vE "^(feat|fix|docs|refactor|perf|chore|build|ci|style|test)(\(.+\))?:" \
    || true)"

if [[ -n "$UNCONVENTIONAL" ]]; then
    HAS_CONTENT=true
    ENTRY+="\n### Other\n"
    while IFS= read -r msg; do
        ENTRY+="- ${msg}\n"
    done <<< "$UNCONVENTIONAL"
fi

if ! $HAS_CONTENT; then
    ENTRY+="\nNo notable changes.\n"
fi

# -- Write changelog --------------------------------------------------------

if [[ -f "$CHANGELOG" ]]; then
    # Insert new entry after the header
    EXISTING="$(cat "$CHANGELOG")"
    # Remove the "# Changelog" header, prepend new entry, re-add header
    BODY="${EXISTING#*$'\n'}"
    {
        echo "# Changelog"
        echo ""
        echo -e "$ENTRY"
        echo "$BODY"
    } > "$CHANGELOG"
else
    {
        echo "# Changelog"
        echo ""
        echo "All notable changes to FromTtyToPretty will be documented in this file."
        echo ""
        echo "Format based on [Conventional Commits](https://www.conventionalcommits.org/)."
        echo ""
        echo -e "$ENTRY"
    } > "$CHANGELOG"
fi

log "Updated CHANGELOG.md"

# -- Write version ----------------------------------------------------------

echo "$NEW_VERSION" > "$VERSION_FILE"
log "Updated VERSION to ${NEW_VERSION}"

# -- Commit and tag ---------------------------------------------------------

git add "$VERSION_FILE" "$CHANGELOG"
git commit -m "chore: release ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"

log "Created commit and tag ${TAG}"

echo ""
info "Next steps:"
echo "  git push origin main"
echo "  git push origin ${TAG}"
echo ""
log "Release ${TAG} ready!"
