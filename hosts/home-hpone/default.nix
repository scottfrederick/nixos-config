{ config, pkgs, lib, inputs, ... }:
{
  # ============================================================
  # home-hpone — personal machine (matches yadm local.class).
  # Migrated from Pop!_OS 24.04 LTS (inventoried 2026-05-23).
  # Hardware: NVMe NVMe, LUKS+LVM+ext4 (Pop), zram swap, x86_64.
  # ============================================================
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/claude-desktop.nix   # Claude Desktop — this host only
    ../../modules/astro.nix            # PSS + ImPPG — this host only
  ];

  networking.hostName = "home-hpone";

  # No per-host overrides currently — the defaults in modules/common.nix
  # (systemd-boot, linuxPackages_latest, zramSwap, GNOME, etc.) match what
  # the source Pop!_OS box ran. Override here if/when this machine needs
  # something the other machine doesn't.
}
