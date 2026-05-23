{ config, pkgs, lib, inputs, ... }:
{
  # ============================================================
  # work-dell — employer-owned machine (matches yadm local.class).
  #
  # NOT YET INVENTORIED. This stub mirrors home-hpone so the
  # flake builds; replace bits below with whatever this machine
  # actually needs.
  # ============================================================
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  networking.hostName = "work-dell";

  # ---- Place per-host overrides here. Examples of things that
  #      legitimately differ between work-dell and home-hpone:
  #
  # services.xserver.videoDrivers = [ "nvidia" ];     # if Dell has NVIDIA
  # hardware.nvidia.modesetting.enable = true;
  # hardware.nvidia.open = false;
  #
  # time.timeZone = "America/New_York";              # if work-dell travels
  # boot.kernelPackages = pkgs.linuxPackages_lts;    # more conservative on a work box
  #
  # # Work-specific extras (corp VPN client, work-issued CA, etc.):
  # services.openconnect.enable = true;
  # security.pki.certificateFiles = [ ./corp-ca.crt ];
  #
  # # Different user groups / sudo policy on work hardware:
  # security.sudo.wheelNeedsPassword = true;
}
