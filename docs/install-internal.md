# Internal-disk install checklist — home-hpone (overwrites Pop!_OS)

This installs NixOS (`home-hpone` flake output) onto the HP One's
**internal NVMe**, destroying the existing Pop!_OS install. Root is
**LUKS-encrypted** (passphrase at every boot).

> **This is the destructive, no-going-back install.** The USB variant
> (`docs/install-target.md`) was the try-before-you-commit test that
> left Pop alone. This one wipes Pop. Read "Before you start" fully.

## Before you start

- **The repo is your only safety net.** It lives at
  `https://github.com/scottfrederick/nixos-config`. The working copy at
  `~/Projects/nixos-config` on Pop dies with the disk — only what's on
  GitHub survives. Before booting the installer, make sure your working
  tree is clean and pushed: `git status` shows nothing to commit and
  `git log --oneline origin/main..HEAD` is empty.
- **Anything else on the Pop disk is gone after step D.** You confirmed
  there's nothing else worth saving. Last chance to copy files off.
- **yadm dotfiles** live in their own remote and are restored by the
  yadm bootstrap on first login — not by this install.
- You need: a NixOS live USB installer (graphical or minimal, 26.05),
  the HP One's firmware boot-menu key, and network access.
- **Pick and remember two secrets:** the **LUKS passphrase** (typed at
  every boot to unlock the disk) and the **login password** for
  `sfrederick`. They can be the same or different; don't lose either —
  the LUKS passphrase is unrecoverable.

## A. Boot the installer

1. Insert the NixOS live USB.
2. Power on; hammer **F9** (fallback **F12** / **Esc**) for the firmware
   boot menu.
3. Pick the installer USB stick (shows as "USB" / the stick's label,
   `iso9660`).
4. At the NixOS boot menu pick the default; wait for the desktop / shell.

## B. Network

Graphical ISO: connect wifi via the GNOME applet.
Minimal ISO:
```sh
sudo systemctl start wpa_supplicant
nmcli device wifi connect "<SSID>" password "<PSK>"
ping -c2 cache.nixos.org
```

## C. Identify disks — DO NOT SKIP

```sh
lsblk -o NAME,SIZE,MODEL,TRAN,ROTA,SERIAL,MOUNTPOINTS
```

Expected entries:
- **SK hynix PC711 NVMe** (953.9G, TRAN=nvme, serial `ASB3N55381CA93J2I`)
  → this is the HP One's internal disk and **the install target**. It
  currently holds the Pop install (partitions `nvme0n1p1`/`p2`/`p3`,
  with a `crypto_LUKS` entry on p3). **We are wiping all of it.**
- **Generic Flash Disk** (TRAN=usb, `iso9660`, mounted under `/iso` or
  `/run/...`) → the live installer. **Do NOT touch.**

**Self-verify before proceeding** (this session is gone once you reboot):

- The **`SK hynix PC711 NVMe`** line is the target. Its device name is
  almost certainly `/dev/nvme0n1`. NVMe partitions are named with a `p`
  separator: `nvme0n1p1`, `nvme0n1p2` (NOT `nvme0n11`).
- The **`Flash Disk`** line is the installer USB. **Do NOT touch.**
- No second NVMe and (ideally) no WD USB HDD present.

If the target is not `/dev/nvme0n1`, substitute the right name in
`DISK=` below. **The model/serial column is authoritative, not the
device name.**

## D. Partition the NVMe (destroys Pop!_OS)

`${DISK}p1`/`${DISK}p2` because NVMe uses a `p` partition separator.

```sh
DISK=/dev/nvme0n1
echo "About to ERASE $DISK (Pop!_OS) — Ctrl+C now if wrong"; sleep 10
sudo wipefs -a $DISK
sudo sgdisk --zap-all $DISK
sudo sgdisk -n1:0:+1GiB -t1:EF00 -c1:BOOT  $DISK   # EFI system partition
sudo sgdisk -n2:0:0     -t2:8309 -c2:luks  $DISK   # LUKS container (rest of disk)
sudo partprobe $DISK
lsblk $DISK
```

Expected: `nvme0n1p1` (1G) and `nvme0n1p2` (~952G).

(EFI is 1 GiB, not 512 MiB as on the USB install — generous headroom for
multiple kernels; harmless.)

## E. LUKS format + open, then format/mount

Set the LUKS passphrase when prompted (twice). This is the boot
passphrase.

```sh
# Create the encrypted container on p2:
sudo cryptsetup luksFormat --type luks2 ${DISK}p2
# Unlock it as the mapper device "cryptroot":
sudo cryptsetup open ${DISK}p2 cryptroot

# Filesystems: EFI on p1, ext4 root inside the unlocked mapper:
sudo mkfs.fat -F32 -n BOOT /dev/disk/by-partlabel/BOOT
sudo mkfs.ext4 -L nixos    /dev/mapper/cryptroot

# Mount:
sudo mount /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-partlabel/BOOT /mnt/boot
lsblk $DISK
```

Expected: `cryptroot` (the dm-crypt mapper) mounted on `/mnt`, and
`nvme0n1p1` mounted on `/mnt/boot`.

**Record the LUKS partition UUID — you need it in step G:**
```sh
sudo blkid ${DISK}p2          # note the UUID="..." (the LUKS partition, NOT cryptroot)
```

## F. Clone the flake

```sh
cd /tmp
git clone https://github.com/scottfrederick/nixos-config
cd nixos-config
git status        # expect: on branch main, clean
```

You want the latest `main`; `git clone` gives you that by default.

## G. Generate hardware-configuration.nix + wire up LUKS

```sh
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/home-hpone/hardware-configuration.nix
```

`nixos-generate-config` produces the `fileSystems` entries but will
**not** add the LUKS unlock stanza. Edit the file and add it by hand:

```sh
nano hosts/home-hpone/hardware-configuration.nix
```

Add inside the top-level attrset (use the UUID of the **LUKS partition**
`${DISK}p2` from step E, not the cryptroot mapper):

```nix
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/PASTE-THE-p2-UUID-HERE";
    allowDiscards = true;        # TRIM passthrough for the NVMe SSD
  };
```

**Verify before continuing:**
- `fileSystems."/"` device uses `/dev/disk/by-uuid/...` and `fsType =
  "ext4"`. (This UUID is the ext4 inside the mapper — different from the
  LUKS partition UUID above. Both are correct in their respective
  places.)
- `fileSystems."/boot"` is present, `fsType = "vfat"`, UUID-based.
- The `boot.initrd.luks.devices.cryptroot.device` UUID matches `blkid
  ${DISK}p2`. **If these two UUIDs are swapped, the machine won't boot.**
- `nixpkgs.hostPlatform = "x86_64-linux";` is present.

## H. Install

Targets `home-hpone` (the internal config — writes real EFI boot vars,
no USB-driver overrides):

```sh
sudo nixos-install --root /mnt --flake .#home-hpone --no-root-passwd
```

Pulls ~14 GB from `cache.nixos.org`. On the NVMe this is far faster than
the USB install was — typically **10-20 minutes**.

After "installation finished" with no failed units, set the login
password:

```sh
sudo nixos-enter --root /mnt -c 'passwd sfrederick'
```

## I. Reboot to the installed system

```sh
sudo umount -R /mnt
sudo cryptsetup close cryptroot
sudo reboot
```

On reboot:
1. **Remove the installer USB stick** so firmware doesn't boot it again.
2. Because `home-hpone` writes EFI boot vars, the firmware should boot
   the internal NVMe automatically — no boot-menu juggling. If it
   doesn't, F9 → pick the internal disk / "NixOS".
3. **LUKS passphrase prompt** appears early (initrd). Type the passphrase
   from step E to unlock the disk.
4. systemd-boot menu → `NixOS - Default`.
5. GDM appears (fast on NVMe — seconds, not the 1-2 min the USB took).
6. Log in as `sfrederick` with the password from step H.

## J. First-boot validation

```sh
hostname                          # expect: home-hpone
systemctl is-system-running       # expect: running (or degraded — check)
systemctl --failed                # expect: 0 loaded units listed
nmcli device status               # expect: wifi connected
lsblk                             # expect: cryptroot mapper over nvme0n1p2, / on it
nix --version                     # expect: nix 2.x with flakes available
nixos-rebuild --help              # confirm rebuild tooling is in PATH
```

If anything surprises you, stop and capture output. Don't run
`nixos-rebuild switch` until first boot is verified clean.

## K. Updating the installation

Now that the internal disk runs `home-hpone`, you update it in place —
no installer USB, no boot-menu dance. From a running session:

```sh
cd /tmp/nixos-config        # or wherever you keep the clone (see note)
git pull
sudo nixos-rebuild switch --flake .#home-hpone
```

Notes:
- `nixos-rebuild switch` acts on the **running system**, so just run it
  while booted normally into `home-hpone`. (This is the difference from
  the USB install, which had to be booted first.)
- `git pull` only brings down committed+pushed changes. Local
  uncommitted edits to the flake are picked up by the rebuild as long as
  you run it from that working copy — flakes read the working tree.
- The `/tmp` clone from install is wiped on reboot. After first boot,
  re-clone somewhere permanent (e.g. `~/Projects/nixos-config`) so the
  yadm-managed `~` and the flake live where the rest of the config
  expects them.

## Troubleshooting

- **Boots straight to the LUKS prompt but the passphrase is rejected:**
  you typed the step-E passphrase wrong, or the `luks.devices.cryptroot.
  device` UUID points at the wrong partition. Boot the installer, `open`
  the device manually to confirm the passphrase, and recheck the UUID in
  the hardware config.
- **No LUKS prompt, drops to an initrd `(initramfs)` / emergency shell:**
  the `boot.initrd.luks.devices` stanza is missing or the UUID is wrong,
  so the initrd can't find/unlock root. Reinstall from step G with the
  corrected UUID.
- **Firmware won't boot the NVMe automatically:** F9 boot menu → pick the
  internal disk. If absent, the EFI vars didn't take — confirm you
  installed `.#home-hpone` (not `.#home-hpone-usb`, which deliberately
  skips writing EFI vars).
- **`nixos-install` fails on a store path / network:** re-run it; it
  resumes. Confirm `ping cache.nixos.org` still works.

## What this checklist deliberately skips

- **Backups** — you confirmed the repo (the only thing worth keeping) is
  pushed; everything else on Pop is disposable.
- **Dual-boot with Pop** — this is a full overwrite, single-OS. No
  shared ESP, no GRUB/os-prober.
- **yadm bootstrap** — runs on first login from its own remote; not part
  of the NixOS install.
- **Recovery/swap partitions** — Pop's recovery partition is not
  recreated; swap is zram (configured in the flake), not a partition.
