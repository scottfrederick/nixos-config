# Target-machine install checklist — home-hpone-usb

Walkthrough for installing the `home-hpone-usb` flake output onto an
external WD 1.8 TB spinning HDD on the HP One, booted from the NixOS
26.05 GNOME live installer USB stick.

This file is meant to be read from a separate device (tablet, phone)
while you type the commands into a terminal on the target machine.

## Before you start

| Media | Plugged into HP One? | Purpose |
|---|---|---|
| NixOS 26.05 GNOME live installer USB stick | Yes (any USB-A port) | Boots the installer |
| WD 1.8 TB external HDD (WD20JDRW) | Yes (USB-C) | **Install target — will be wiped** |

The HP One's internal NVMe is **not** to be touched. Confirm device names
in step C before any destructive command.

---

## A. Boot the installer

1. Power on the HP One.
2. Hammer **F9** until the boot menu appears. (HP One = F9 on most
   models. Fallbacks: F12, Esc.)
3. Select the installer USB stick (likely listed as "Generic Flash Disk"
   or "USB Hard Drive").
4. NixOS GNOME live session boots. Username: `nixos`, no password.

## B. Network

1. Top-right system menu → Wi-Fi → connect to your network.
2. Open Terminal (Ctrl+Alt+T, or Activities → Terminal).
3. Test reachability:
   ```sh
   curl -sI https://github.com | head -1
   ```
   Should print `HTTP/2 200`.

## C. Identify disks — DO NOT SKIP

Run:
```sh
lsblk -o NAME,SIZE,MODEL,TRAN,ROTA,SERIAL,MOUNTPOINTS
```

Expected entries:
- **WDC WD20JDRW** (1.8T, ROTA=1, TRAN=usb, serial `WD-WX32A958JEJJ`) →
  this is the **install target**.
- **Generic Flash Disk** (29.3G, TRAN=usb, iso9660 mounted on
  `/iso` and `/run/...`) → this is the installer. **Do NOT touch.**
- Internal NVMe (whatever model the HP One has) → **Do NOT touch.**

Find the device name of the WD drive. Almost certainly `/dev/sda` since
USB devices come up before NVMe, but **confirm** — the model column is
authoritative, not the device name.

**Send the lsblk output to Claude before proceeding**, or at minimum
read it carefully yourself and make sure the WD drive's path is correct
in the `DISK=` line below.

## D. Partition the WD drive

Replace `sdX` with the actual device name from step C if it's not `sda`.

```sh
DISK=/dev/sda
echo "About to wipe $DISK — Ctrl+C to abort if wrong"; sleep 5
sudo wipefs -a $DISK
sudo sgdisk --zap-all $DISK
sudo sgdisk -n1:0:+512MiB -t1:EF00 -c1:BOOT $DISK
sudo sgdisk -n2:0:0       -t2:8300 -c2:nixos $DISK
sudo partprobe $DISK
lsblk $DISK
```

Expected `lsblk $DISK` output: the disk with two new partitions, e.g.
`sda1` (512M) and `sda2` (~1.8T).

## E. Format and mount

```sh
sudo mkfs.fat -F32 -n BOOT  ${DISK}1
sudo mkfs.ext4 -L nixos     ${DISK}2
sudo mount ${DISK}2 /mnt
sudo mkdir -p /mnt/boot
sudo mount ${DISK}1 /mnt/boot
lsblk $DISK
```

Expected: `sda1` mounted on `/mnt/boot`, `sda2` mounted on `/mnt`.

## F. Clone the flake

```sh
cd /tmp
git clone https://github.com/scottfrederick/nixos-config
cd nixos-config
git log --oneline -3
```

Top commit should be `flake: pin to nixos-26.05 + add home-hpone-usb USB-boot host`.

## G. Generate hardware-configuration.nix and drop into flake

```sh
sudo nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/hardware-configuration.nix` reflecting the
just-mounted partitions. Copy it into the flake (replacing the
placeholder):

```sh
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/home-hpone/hardware-configuration.nix
cat hosts/home-hpone/hardware-configuration.nix
```

**Verify before continuing:**
- `fileSystems."/"` device line uses `/dev/disk/by-uuid/...` (UUID, not
  `/dev/sda2`). If not, stop and let Claude know.
- `fileSystems."/boot"` is present and similarly UUID-based.
- `fsType = "ext4"` for `/`, `fsType = "vfat"` for `/boot`.
- Add `options = [ "noatime" ];` to the root entry if not present —
  spinning HDD wants this. Edit with `sudo nano
  hosts/home-hpone/hardware-configuration.nix` if needed.

## H. Install

```sh
sudo nixos-install --root /mnt --flake .#home-hpone-usb --no-root-passwd
```

Pulls ~14 GB from `cache.nixos.org`. On a USB spinning HDD this will
take **30-60 minutes**. The download is fast; the per-store-path linking
into the rootfs is what drags.

After the install finishes successfully ("installation finished" message,
no failed units listed), set the user password:

```sh
sudo nixos-enter --root /mnt -c 'passwd sfrederick'
```

Pick a password you'll remember — you'll log in with it at GDM.

## I. Reboot to the installed system

```sh
sudo umount -R /mnt
sudo reboot
```

On reboot:
1. **Unplug the installer USB stick** so firmware doesn't boot it again.
2. Hammer F9 → pick the WD HDD ("USB Hard Drive" or "WD" in the menu).
3. systemd-boot menu → pick `NixOS - Default`.
4. Be patient — GDM should appear after **1-2 minutes** (spinning USB
   disk; this is normal).
5. Log in as `sfrederick` with the password from step H.

## J. First-boot validation

After login, open a terminal:

```sh
hostname                          # expect: home-hpone-usb
systemctl is-system-running       # expect: running (or degraded — check)
systemctl --failed                # expect: 0 loaded units listed
nmcli device status               # expect: wifi connected
nix --version                     # expect: nix 2.x with flakes available
nixos-rebuild --help              # confirm rebuild tooling is in PATH
```

If any of these surprise you, stop and capture output for Claude. Don't
run `nixos-rebuild switch` yet — first iteration on this hardware should
be a deliberate, verified step.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| F9 doesn't show a boot menu | HP firmware varies | Try F12, Esc, F10, F2 on power-on |
| Wi-Fi adapter not detected in installer | Newer NIC needing firmware | `nmcli device status` to check; try a USB-Ethernet adapter as fallback |
| `nixos-generate-config` mentions LUKS | We didn't ask for encryption | Re-check `/mnt` is mounted on the WD, not internal |
| Install errors with "no space left" | Wrong disk picked | STOP, do not retry; identify the right disk |
| Long pause during install with disk-light off | Cache fetch over Wi-Fi | Be patient, no action needed |
| Install completes but reboot loops to firmware | EFI variable not written (intentional: `canTouchEfiVariables=false`) | Use F9 boot menu every boot to pick the WD HDD |

## What this checklist deliberately skips

- LUKS / LVM (the migration notes classified disk encryption as
  flag-for-manual / user-deferred).
- Setting up SSH access into the installed system.
- yadm bootstrap on first login (handled by yadm's own bootstrap script
  the first time you run `yadm clone`).
- Flatpak app installs (handled by `yadm bootstrap` →
  `50-flatpak-apps.sh`).
