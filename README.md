# FromTtyToPretty

Post-install bootstrap scripts for Arch Linux + Hyprland. Pick a profile, get a desktop.

## Quick Start

```bash
git clone https://github.com/bjschnell/FromTtyToPretty.git
cd FromTtyToPretty
chmod +x bootstrap.sh scripts/*.sh
./bootstrap.sh
```

## Profiles

Run everything unattended with `--profile`, or launch the interactive picker with no args.

| Profile | What it installs |
|---------|-----------------|
| `minimal` | paru, core packages (ghostty, brave, nvim, tailscale), dotfiles |
| `desktop` | minimal + hyprland rice (waybar, wofi, dunst, swww, hyprlock, pipewire, fonts, theming) |
| `homelab` | minimal + docker + homelab tools (btop, ncdu, lazydocker, eza, fzf, zoxide, tmux, etc.) |
| `full` | everything |

```bash
# Preset profile — shows what will run, confirms, then goes
./bootstrap.sh --profile minimal
./bootstrap.sh --profile desktop
./bootstrap.sh --profile homelab
./bootstrap.sh --profile full

# Interactive — asks yes/no for each script
./bootstrap.sh --interactive

# Just see what's in each profile
./bootstrap.sh --list
```

## Scripts

```
bootstrap.sh              # Entry point — profile picker or per-script prompts
lib/
  common.sh               # Shared helpers (colors, logging, guards)
scripts/
  00-paru.sh              # AUR helper (built from source)
  01-core.sh              # Ghostty, Brave, Neovim + LazyVim, Tailscale
  02-desktop.sh           # Hyprland + full rice
  03-docker.sh            # Docker, docker-compose, docker-buildx
  04-homelab.sh           # CLI tools for servers and tinkering
  05-dotfiles.sh          # Git bare repo dotfiles setup
```

Every script is idempotent — safe to re-run. Each can also be run standalone:

```bash
bash scripts/03-docker.sh
```

## Dotfiles

Uses the **git bare repo** pattern (no stow, no symlink scripts). After running `05-dotfiles.sh`:

```bash
# Track a config file
dotfiles add ~/.config/hypr/hyprland.conf
dotfiles commit -m "hyprland config"
dotfiles push

# Status (untracked files hidden by default)
dotfiles status
```

Set `DOTFILES_REMOTE` in `scripts/05-dotfiles.sh` to your repo URL for automatic cloning on fresh installs.

## Adding Scripts

1. Create `scripts/06-whatever.sh` (source `lib/common.sh` at the top)
2. Add an entry to the `SCRIPTS` array in `bootstrap.sh`:
   ```
   "06-whatever.sh:Description here:homelab,full"
   ```
3. The tags after the last `:` control which profiles include it

## Versioning

Uses semantic versioning. The current version lives in `VERSION` and is shown via `./bootstrap.sh --version`.

### Commit Convention

This repo uses [Conventional Commits](https://www.conventionalcommits.org/) for auto-generated changelogs:

```
feat: add nvidia driver script
fix: correct paru clone URL
docs: update profile table in README
refactor: simplify package arrays
chore: clean up temp directory handling
```

### Cutting a Release

```bash
./release.sh patch    # 0.1.0 -> 0.1.1
./release.sh minor    # 0.1.0 -> 0.2.0
./release.sh major    # 0.1.0 -> 1.0.0
```

This bumps `VERSION`, generates a changelog entry from commits since the last tag, commits, and creates a git tag. Then push:

```bash
git push origin main
git push origin v0.2.0
```

## License

MIT
