{ pkgs, ... }:
{
  # ============================================================
  # Docker. Matches yadm bootstrap 40-apt-apps.sh (apt/docker.sh).
  #
  # On NixOS, install the daemon declaratively; the `docker` group
  # is added to the user in users.nix.
  # ============================================================
  virtualisation.docker = {
    enable = true;
    # Reclaim disk on a schedule (parity with Pop's docker-clean script).
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
