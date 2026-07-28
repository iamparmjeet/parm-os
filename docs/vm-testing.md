# VM testing

## Golden input

Install `/home/parm/Downloads/omarchy-3.8.4.iso`, complete the encrypted Btrfs
installation, then run:

```bash
./tools/vm/prepare-quattro
```

After reboot, confirm that Quickshell and Lua Hyprland configuration are
active. Take a snapshot named `omarchy-quattro-golden`.

## Parm conversion

```bash
./setup inspect
./setup convert --vm-test --dry-run
./setup convert --vm-test
```

Reboot twice. The first healthy boot removes Omarchy while retaining its UKI.
The second healthy boot retires the rescue UKI.

Expected phases:

```bash
cat /var/lib/parm/conversion-phase
```

Values progress from `staged` to `validated` to `complete`.

## Snapshot names

- `omarchy-3.8.4-clean`
- `omarchy-quattro-golden`
- `parm-staged`
- `parm-first-boot`
- `parm-verified`

Repeat the complete workflow in QEMU/KVM and VirtualBox. The VirtualBox helper
will refuse to proceed until `/dev/vboxdrv` is available; it never repairs the
host automatically.
