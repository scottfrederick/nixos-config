# PLACEHOLDER — REPLACE BEFORE BUILDING ON A REAL MACHINE
#
# On the target machine, after booting the NixOS installer:
#
#     sudo nixos-generate-config --root /mnt
#
# Then copy /mnt/etc/nixos/hardware-configuration.nix over this file.
#
# Source-system disk topology (for reference, NOT to be reused verbatim):
#   /dev/nvme0n1
#     ├─ p1 vfat  512M  -> /boot/efi   (label EFI)
#     ├─ p2 vfat    4G  -> /recovery   (Pop's recovery; not needed on NixOS)
#     └─ p3 LUKS  949G
#          └─ cryptdata (LVM2)
#               └─ data-root ext4 -> /
#   zram0 swap 16G
#
# If you want LUKS+LVM on the new machine, after nixos-generate-config also add:
#
#   boot.initrd.luks.devices.cryptdata = {
#     device = "/dev/disk/by-uuid/<NEW-MACHINE-UUID>";
#     allowDiscards = true;
#   };
#   services.lvm.enable = true;
#
# (Disk encryption was classified flag-for-manual / user-deferred.
#  Default in this placeholder is unencrypted ext4.)

{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ ];

  # Replace with the real fileSystems / boot.initrd settings from
  # `nixos-generate-config` output on the target machine.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";   # change to actual label
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";    # change to actual label
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
}
