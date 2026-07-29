# Version 2: application installation and theming

Version 2 will add optional installation and curated settings for:

- Zed
- Dolphin
- Kate
- Gwenview
- Qt6ct/KDE color and icon dependencies

A repository-owned `theme-sync` command will replace the currently obsolete
Omazed and Qt scripts. It will read the active Omarchy 4 theme from:

```text
~/.local/state/omarchy/current/theme/colors.toml
~/.local/state/omarchy/current/theme/icons.theme
```

The command will generate a stable Zed theme, KDE color scheme, Qt6ct color
scheme, and icon alias. A hook under
`~/.config/omarchy/hooks/theme-set.d/` will run it after every Omarchy theme
change.

Generated colors will remain outside Git. Zed authentication, recent files,
KDE histories, and window geometry will remain excluded.
