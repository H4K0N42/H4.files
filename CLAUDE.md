# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal NixOS dotfiles for a single machine: host `notoast`, user `hagen`, repo checked out at
`~/H4.files`. There is no application code, no test suite, and no build system beyond Nix.
"Building" means rebuilding the system or the home environment.

## Commands

```bash
# Apply changes (what ~/scripts/update.sh does; nh reads NH_OS_FLAKE / NH_HOME_FLAKE)
nh os switch -u                  # system generation
nh home switch -u                # home-manager generation

# Evaluate/build without activating — use these to check a change compiles
nix build ./nix/desktop/system#nixosConfigurations.notoast.config.system.build.toplevel
nix build ./nix/desktop/home-manager#homeConfigurations.hagen.activationPackage

nixfmt <file>.nix                # formatting convention for all Nix files
pre-commit run --all-files       # gitleaks secret scan (only configured hook)
git submodule update --init      # scripts/external/niri_tweaks
```

`flake.lock` files are committed (the ignore rule in `.gitignore` is commented out); `-u` on the
`nh` commands bumps them.

## Architecture

Two independent flakes, both pinning `nixos-26.05` and additionally importing `nixos-unstable` as an
`unstable` arg passed through `specialArgs` / `extraSpecialArgs`. Packages are pulled from `unstable`
selectively by appending a second list to `environment.systemPackages` / `home.packages`.

- `nix/desktop/system/` — `nixosConfigurations.notoast`. `configuration.nix` is just an import list of
  numbered modules: `1-config` (users, nix settings, portals), `2-boot`, `3-nvidia`, `4-devices`,
  `5-network`, `6-locale`, `7-packages` (system packages **and** all `services`/`programs`/
  `virtualisation` blocks — this is the largest and most-edited module), `8-ai`.
  `NH_OS_FLAKE=/etc/nixos`, so this directory is expected to be symlinked to `/etc/nixos`.
- `nix/desktop/home-manager/` — `homeConfigurations."hagen"`. `~/.config/home-manager` is a symlink to
  this directory, so `nh home switch` evaluates the repo in place.

### How config/ reaches the live system (the important part)

`home.nix` defines `dots = builtins.toPath ../../..` (the repo root) and wires directories in via
`home.file`. There are **three different propagation paths**, and knowing which one applies decides
whether an edit needs a rebuild:

1. **Copied into the Nix store** — `icons/`, `themes/`, `scripts/`, `config/ghostty`, `config/hypr`,
   `config/waybar`, `config/niri/config.kdl`, `config/niri/tilemod_config.toml`.
   Edits here are inert until `nh home switch`. `~/scripts` is a store symlink, not the repo.
2. **Live symlink outside home-manager** — `~/.config/noctalia` → `config/noctalia/`. Edits take effect
   immediately, and the running shell writes back to these files (`settings.json`, `colors.json`
   routinely show up dirty in `git status`).
3. **Live via `include` indirection** — home-manager only manages `config/niri/config.kdl`, whose sole
   line is `include "~/H4.files/config/niri/loader.kdl"`. `loader.kdl` then includes `startup.kdl`,
   `binds.kdl`, `input.kdl`, `outputs.kdl`, `design.kdl`, `windows.kdl`, `misc.kdl` straight from the
   repo. Editing any of those is picked up by niri's hot reload with no rebuild. Adding a new `.kdl`
   file requires adding it to `loader.kdl`.

Because of (1) and `dots`, the repo must stay at `~/H4.files`.

### Window managers

niri is the active compositor (`programs.niri.enable = true`; `programs.hyprland.enable = false`).
`config/hypr/` is a kept-but-inactive parallel setup — the two config trees duplicate keybinds and
autostart entries, so a behavioural change usually belongs in `config/niri/binds.kdl` +
`config/niri/startup.kdl` only. Hyprland-specific scripts (`scripts/mousemode.sh` uses `hyprctl`,
`scripts/dc_mute/` talks to the Hyprland IPC socket) are likewise stale under niri.

The bar/shell is noctalia (quickshell-based), configured under `config/noctalia/` including a QML
plugin in `config/noctalia/plugins/mullvad/`.

### scripts/

Each helper with Python deps is a directory containing `run.sh` + `shell.nix`; `run.sh` does
`cd /home/hagen/scripts/<name> && nix-shell --run "python3 <name>.py"`. That path is the store copy,
so **edit the repo, then `nh home switch`, then run** — running from the repo directly will use the
old code. `midivol` (MIDI fader → per-app PipeWire volume) and `movecur` are launched from
`config/niri/startup.kdl`; `soundboard/run.sh` builds PipeWire null-sink/loopback routing.
`scripts/external/niri_tweaks` is a git submodule (upstream `heyoeyo/niri_tweaks`).
