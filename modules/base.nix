{ config, pkgs, lib, inputs, ... }:
{
  # ============================================================
  # System packages translated 1:1 from `apt-mark showmanual`
  # on the source Pop!_OS box. Items that did not translate
  # cleanly were dropped (per user decision 2026-05-23).
  # ============================================================
  environment.systemPackages = with pkgs; [
    SDL  # from apt: libsdl1.2debian
    arphic-ukai  # from apt: fonts-arphic-ukai
    arphic-uming  # from apt: fonts-arphic-uming
    cmake  # from apt: cmake
    faad2  # from apt: libfaad2
    fluidsynth  # from apt: libfluidsynth3
    geary  # from apt: geary
    ghostty  # from apt: ghostty
    gnome-calculator  # from apt: gnome-calculator
    gnome-text-editor  # from apt: gedit
    gnome-video-effects  # from apt: gnome-video-effects
    gnome-weather  # from apt: gnome-weather
    gst_all_1.gst-libav  # from apt: gstreamer1.0-libav
    gst_all_1.gst-plugins-bad  # from apt: gstreamer1.0-plugins-bad
    hplip  # from apt: hplip
    ibus-engines.chewing  # from apt: ibus-chewing
    ibus-engines.libpinyin  # from apt: ibus-libpinyin
    ibus-engines.table-others  # from apt: ibus-table-cangjie3
    inkscape  # from apt: inkscape
    libdvdnav  # from apt: libdvdnav4
    libdvdread  # from apt: libdvdread8t64
    lrdf  # from apt: liblrdf0
    multipath-tools  # from apt: kpartx
    nautilus  # from apt: nautilus
    neon  # from apt: libneon27t64
    noto-fonts  # from apt: fonts-noto-ui-core
    noto-fonts-cjk-sans  # from apt: fonts-noto-cjk
    openal  # from apt: libopenal-data
    openh264  # from apt: libopenh264-7
    python3  # from apt: python3.10
    sndio  # from apt: libsndio7.0
    soundtouch  # from apt: libsoundtouch1
    spandsp  # from apt: libspandsp2t64
    totem  # from apt: totem
    vim  # from apt: vim
    vim-full  # from apt: vim-gtk3
    vo-aacenc  # from apt: libvo-aacenc0
    vo-amrwbenc  # from apt: libvo-amrwbenc0
    wildmidi  # from apt: libwildmidi2
    yadm  # from apt: yadm
    xxd  # from apt: xxd
    zbar  # from apt: libzbar0t64
    zsh  # from apt: zsh
    zxing-cpp  # from apt: libzxing3
    libbpf  # REVIEW: matched after stripping suffix: 'libbpf' (from apt: libbpf0)
    libdc1394  # REVIEW: matched after stripping suffix: 'libdc1394' (from apt: libdc1394-25)
    libestr  # REVIEW: matched after stripping suffix: 'libestr' (from apt: libestr0)
    libfastjson  # REVIEW: matched after stripping suffix: 'libfastjson' (from apt: libfastjson4)
    libffado  # REVIEW: matched after stripping suffix: 'libffado' (from apt: libffado2)
    libltc  # REVIEW: matched after stripping suffix: 'libltc' (from apt: libltc11)
    libmodplug  # REVIEW: matched after stripping suffix: 'libmodplug' (from apt: libmodplug1)
    libmpcdec  # REVIEW: matched after stripping suffix: 'libmpcdec' (from apt: libmpcdec6)
    libmysofa  # REVIEW: matched after stripping suffix: 'libmysofa' (from apt: libmysofa1)
    libunistring  # REVIEW: matched after stripping suffix: 'libunistring' (from apt: libunistring2)
    libxcb-cursor  # REVIEW: matched after stripping suffix: 'libxcb-cursor' (from apt: libxcb-cursor0)
    pptpd  # REVIEW: explicit map suggested 'networkmanager-pptp' but only fuzzy  (from apt: network-manager-pptp-gnome)
    saxon  # REVIEW: fuzzy match: 'saxon' (from apt: libwpe-1.0-1)
    snicat  # REVIEW: explicit map suggested 'libressl-netcat' but only fuzzy matc (from apt: netcat-openbsd)
    soundfont-ydp-grand  # REVIEW: fuzzy match: 'soundfont-ydp-grand' (from apt: timgm6mb-soundfont)
    sushi  # REVIEW: explicit map suggested 'nautilus-sendto' but only fuzzy matc (from apt: nautilus-sendto)

    # ---- Always-on essentials (not from apt; common NixOS practice) ----
    bash  # ensure bash is in the system profile; /bin/bash symlink below
    pass  # password-store: standard-unix-password-manager
    gnupg  # gpg cli
    git-credential-manager  # cross-platform git credential helper
    inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default  # flox (github:flox/flox flake)
    git
    wget
    curl
    gnumake
    unzip
    zip
    tree
    htop
    ripgrep
    fd
    jq
    file
    lsof
    pciutils
    usbutils
    dmidecode
    gnome-tweaks
    brave
  ];

  # ============================================================
  # Services that map cleanly from the source system's enabled list
  # ============================================================

  # Source: bluetooth.service active (yes, BT was enabled on Pop).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Source: cups.service enabled (HP printer support via hplip in pkgs).
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Source: chrony.service enabled.
  services.chrony.enable = true;

  # Source: systemd-resolved.service enabled.
  services.resolved.enable = true;

  # Source: apparmor was active.
  security.apparmor.enable = true;

  # Source: switcheroo-control.service enabled (hybrid GPU helper).
  services.switcherooControl.enable = true;

  # Source: udisks2 used by file manager / GNOME — auto-pulled by GNOME, kept explicit for clarity.
  services.udisks2.enable = true;

  # ------------------------------------------------------------
  # Sudo / polkit
  # ------------------------------------------------------------
  security.sudo.enable = true;
  security.polkit.enable = true;

  # Allow unfree (required for: virtualbox if re-added, intel-microcode, some firmware, etc.).
  nixpkgs.config.allowUnfree = true;

  # CPU microcode (will only apply if matching CPU).
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ------------------------------------------------------------
  # /bin/bash — NixOS only provides /bin/sh (via environment.binsh)
  # out of the box; there is no built-in option for /bin/bash. Create
  # it declaratively as a tmpfiles symlink. "L+" forces replacement of
  # any pre-existing path, and the rule is re-applied on activation/boot.
  # ------------------------------------------------------------
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];
}
