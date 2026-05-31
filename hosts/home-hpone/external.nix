{ config, pkgs, lib, ... }:
{
  # ============================================================
  # home-hpone-usb — NixOS booting from an external USB drive,
  # intended as a try-before-you-commit test of the home-hpone
  # config on real hardware (without disturbing the source Pop
  # install on the internal disk).
  #
  # Imports the real home-hpone host config, then overrides a
  # handful of settings that matter for USB-booted, removable-disk
  # NixOS:
  #   - Don't write firmware EFI variables (the entry would be
  #     orphaned when the drive is unplugged).
  #   - Force USB storage drivers into initrd (so the kernel can
  #     read the rootfs before userspace is up).
  #   - Distinct hostname so it's obvious which OS booted.
  # ============================================================
  imports = [ ./default.nix ];

  # Override hostname so a "this is the USB image" signal is visible
  # in shell prompts, syslog, GDM, etc. yadm's local.class still gets
  # set to home-hpone at first login (see install-yadm-nixos.sh).
  networking.hostName = lib.mkForce "home-hpone-usb";

  # ----- USB-boot-specific bootloader settings ---------------------------
  # canTouchEfiVariables=false: do NOT register a boot entry in the
  # firmware's boot order. We'll select the USB drive from the firmware
  # boot menu (typically F12) when we want to boot it. With it true,
  # systemd-boot would write an EFI variable pointing at the USB drive
  # by partition GUID — fine while it's plugged in, but leaves a stale
  # entry in the firmware once you unplug.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # ----- USB drivers in initrd ------------------------------------------
  # nixos-generate-config usually picks these up from currently-loaded
  # modules, but only if the install host actually has them loaded.
  # Force them so the rootfs on the USB drive is reachable before
  # userspace.
  boot.initrd.availableKernelModules = [
    "xhci_pci"      # USB 3 host controller
    "ehci_pci"      # USB 2 host controller (some firmwares present this first)
    "usb_storage"   # mass-storage class
    "usbhid"        # keyboard at boot prompt
    "uas"           # USB-attached SCSI (faster transfer mode used by SSD enclosures)
    "sd_mod"        # SCSI disk
    "ahci"          # in case the USB enclosure exposes its disk via AHCI
    "nvme"          # in case the USB enclosure houses an NVMe SSD
  ];

  # No internal zram (the source's pop-default-settings-zram). On a USB
  # boot the spinning-or-USB-SSD root is the slow path; zram is fine but
  # let's reduce write amplification on the USB SSD by tuning a touch
  # more conservatively. Disabling outright would mean GNOME hits OOM
  # on small RAM; keep it on but smaller.
  zramSwap.memoryPercent = lib.mkDefault 25;
}
