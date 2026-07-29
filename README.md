# Parm Config

Parm Config is a portable customization layer for Omarchy 4.x. Omarchy remains
the operating system and desktop foundation; this repository owns only Parm's
personal Hyprland, Omarchy Shell, bar, Zsh, terminal, and CLI overrides.

The previous Parm OS converter is preserved at
`archive/parm-os-0.1.0-dev`. The former `system-dotfiles` history is preserved
at `archive/system-dotfiles`.

## What is saved

- Hyprland keybindings, touchpad settings, gaps, and Web-AI rules
- Omarchy Shell layout, styling, branding, menu extension, and local plugins
- Web-AI and focused-display helper scripts
- Zsh, tmux, Oh My Posh, Alacritty, btop, and fastfetch preferences
- An optional `parm-laptop` monitor and DDC/CI brightness profile
- A pinned reference to the Kanagawa Dragon Omarchy theme

Generated state, browser profiles, credentials, app histories, backups,
unchanged Omarchy templates, and legacy End-4/Quickshell components are not
saved.

## Inspect

```bash
./setup status
./setup status --profile parm-laptop
./setup status --json
```

## Install

Always inspect first:

```bash
./setup install --dry-run --profile parm-laptop
```

A normal install writes missing files but refuses existing differences without
changing anything. To replace existing files, create a timestamped backup and
apply the repository versions:

```bash
./setup install --force --profile parm-laptop
```

Packages are opt-in:

```bash
./setup install --force --packages --profile parm-laptop
```

Backups are stored under
`${XDG_STATE_HOME:-$HOME/.local/state}/parm-config/backups/`.

## Save later changes

Preview live drift:

```bash
./setup capture --profile parm-laptop
```

After reviewing it, write capturable live files into the repository:

```bash
./setup capture --write --profile parm-laptop
```

Capture rejects hard-coded home paths and never includes generated or
unmanaged files.

## Restore

```bash
./setup backups
./setup restore <backup-id> --dry-run
./setup restore <backup-id> --yes
```

See `docs/managed-files.md`, `docs/profiles.md`, and
`docs/v2-app-theming.md` for scope and design details.
