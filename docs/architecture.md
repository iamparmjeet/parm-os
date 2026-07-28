# Parm architecture

Parm has four boundaries:

1. `setup` owns staged installation, snapshots and conversion state.
2. `parmctl` is the stable user interface for configuration and desktop tasks.
3. The long-running Quickshell process owns only desktop presentation.
4. The separate Settings Quickshell process starts on demand and writes through
   `parmctl`.

Product files are immutable under `/usr/share/parm`. User configuration and
overrides live under `~/.config/parm`. Generated Material outputs live under
`~/.cache/parm/themes` and switch atomically.

## Conversion phases

- `staged`: Parm and its UKI exist beside Omarchy.
- `validated`: a healthy Parm session allowed Omarchy package cleanup; rescue
  UKI remains.
- `complete`: a second healthy boot allowed rescue UKI removal.

No health marker means no cleanup.

## Security

Pre-release conversion requires a supported VM. Test-root mode rejects broad
or live paths. The graphical Settings backend does not receive blanket sudo.

## Licensing

New code is MIT. Omarchy's architectural influence and any later imported MIT
code retain attribution. end-4 source and assets are not included.
