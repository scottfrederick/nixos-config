{ pkgs, ... }:
{
  # ============================================================
  # Source user `sfrederick` (UID 1000, home /home/sfrederick,
  # login shell zsh). NixOS replicates this.
  #
  # Password is NOT set here. Use `passwd sfrederick` after install,
  # or define `users.users.sfrederick.hashedPassword = "..."`.
  # ============================================================
  programs.zsh.enable = true;

  users.users.sfrederick = {
    isNormalUser = true;
    description = "Scott Frederick";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"
      "video"
      "audio"
      "input"
      "dialout"         # serial (was implicit on Pop)
      "docker"          # from modules/docker.nix (added 2026-05-23)
      # "vboxusers"     # uncomment if/when you add the virtualbox module
    ];
    shell = pkgs.zsh;
    # SSH authorized keys: classified flag-for-manual / user-deferred.
    # openssh.authorizedKeys.keys = [ "" ];
  };
}
