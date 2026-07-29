# Profiles

## `parm-laptop`

This profile saves the current two-monitor layout:

- `HDMI-A-1`: 2560×1440 at 60 Hz, position 0×0, scale 1
- `eDP-1`: 1920×1080 at 60 Hz, position 2560×0, scale 1

It also installs focused-display brightness keybindings and enables DDC/CI for
compatible external displays. Laptop brightness and DPMS continue through
Omarchy's stock implementation.

The installer checks for both connector names. If they are not detected, it
refuses the profile unless `--force` is supplied.

Use:

```bash
./setup status --profile parm-laptop
./setup install --dry-run --profile parm-laptop
./setup install --force --profile parm-laptop
```
