# Parm

Parm is a minimal, Material 3 Hyprland desktop built on Arch Linux. It keeps
the useful workflow and keyboard habits of Omarchy Quattro while replacing
Omarchy with an independently branded, wallpaper-derived desktop.

This repository is pre-release. Conversion is intentionally restricted to
virtual machines.

## Safety

The only supported input is an Omarchy Quattro virtual machine. Inspect and
dry-run first:

```bash
./setup inspect
./setup convert --vm-test --dry-run
./setup convert --vm-test
```

The converter installs Parm beside Omarchy, boots Parm, verifies the desktop,
then removes Omarchy. Cleanup never runs before a healthy Parm session.

Do not use this development build on physical hardware.

## Development

```bash
./tests/run
./tools/verify-host-untouched capture
# work only inside this repository
./tools/verify-host-untouched verify
```

See `docs/architecture.md` and `docs/vm-testing.md`.
