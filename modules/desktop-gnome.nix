{ config, pkgs, lib, ... }:
{
  # ============================================================
  # GNOME on Wayland with GDM as display manager.
  #
  # Per user decision 2026-05-23: target is GNOME, not COSMIC.
  # Source system used COSMIC; ~/.config/cosmic/* is captured in
  # artifacts/raw/cosmic_config_values/ for archival only.
  # ============================================================

  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  # `gdm.wayland` removed in GNOME 50 (Wayland is the only supported mode now).

  # Source: XKBLAYOUT=us, KEYMAP=us-acentos (US international with dead keys).
  console.keyMap = "us-acentos";
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";   # closest equivalent to us-acentos in X/Wayland
  };

  # Sound: PipeWire (NixOS default since 22.05; replaces PulseAudio).
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # GNOME's optional bits — match what the source had installed via apt.
  programs.gnome-disks.enable = true;
  programs.evince.enable = true;
  # file-roller is now a plain package; install via environment.systemPackages.
  environment.systemPackages = [ pkgs.file-roller ];

  # Excluded apps the user is unlikely to want (Pop had them as defaults; drop on a fresh GNOME).
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany       # GNOME Web — user has Brave (flatpak) instead
    geary          # source had it, but Flatpak alternatives are typical
    gnome-music    # user has Spotify (flatpak)
    gnome-maps
    gnome-contacts
    gnome-weather  # source had weather-applet (flatpak/cosmic); GNOME's is redundant
    yelp
    totem          # REVIEW: source apt had totem; remove this line if you want it
  ];

  # XDG portals (needed for Flatpak + Wayland screen-share + 1Password browser integration).
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common.default = [ "gnome" ];
  };

  # ibus input methods (source had several ibus-* engines installed; preserve common ones).
  # REVIEW: trim engines list if you don't actually use them.
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin     # ibus-libpinyin (Chinese)
      chewing       # ibus-chewing (Chinese Zhuyin)
      table         # ibus-table-* (Cangjie/Wubi/Quick — all share `table`)
      table-others
    ];
  };
}
