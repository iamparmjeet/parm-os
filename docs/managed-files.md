# Managed files

`config/manifest.json` is the source of truth for core files.
`profiles/parm-laptop/manifest.json` adds host-specific files when the profile
is selected.

Each entry declares:

- a stable ID;
- its repository source;
- its home-relative destination;
- the installed file mode;
- whether live changes may be captured;
- whether it is generated.

The installer rejects absolute destinations and path traversal.

## Deliberate exclusions

- `/usr/share/omarchy` and all packaged Omarchy source
- Omarchy runtime state under `~/.local/state`
- browser profiles, cookies, sessions, caches, and credentials
- Git identity and credential helpers
- application recent-file lists and window geometry
- backups and upgrade snapshots
- Neovim, Zed, and KDE application preferences in v1
- Atuin account state and Mise tool state
- unused Kitty, Starship, and Oh My Posh theme files
- the legacy raw bar module, disabled Quickshell boot hook, and obsolete theme
  scripts
- the Kanagawa theme's optional Quickshell navbar and quick-app launcher

Known legacy files are listed with exact SHA-256 checksums in
`config/retired-v1.tsv`. They are retired only during a forced installation
and only when their content still matches the inspected legacy version.
