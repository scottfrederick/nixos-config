{ config, pkgs, lib, ... }:
{
  # ============================================================
  # Settings common to all of sfrederick's machines.
  # Per-host files override anything they want to differ.
  # ============================================================
  imports = [
    ./base.nix
    ./desktop-gnome.nix
    ./networking.nix
    ./fonts.nix
    ./locale.nix
    ./flatpak.nix
    ./onepassword.nix
    ./nix-settings.nix
    ./users.nix
    ./nix-ld.nix
    ./docker.nix
  ];

  # ----- Bootloader -------------------------------------------------------
  # Pop!_OS used systemd-boot via kernelstub. systemd-boot is the default
  # for both machines; override in hosts/<host>/default.nix if needed.
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Recent kernel by default. A host can pin a different one (e.g. _lts) by
  # setting boot.kernelPackages explicitly — mkDefault loses to a direct
  # assignment.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # zram swap on by default (matches Pop's pop-default-settings-zram).
  zramSwap.enable = lib.mkDefault true;

  # 32-bit multilib graphics — source had ~29 :i386 apt placeholders.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # State version — fix this on first install per host, never change after.
  # Defaulting here so a fresh host inherits a sane value; per-host files
  # can override if the install happens against a different nixpkgs.
  system.stateVersion = lib.mkDefault "25.05";
}
