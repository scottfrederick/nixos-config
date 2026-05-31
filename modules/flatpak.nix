{ pkgs, ... }:
{
  # ============================================================
  # Flatpak runtime + Flathub remote.
  # This module only enables flatpak and registers the Flathub remote.
  # The actual flatpak app installs are handled by the yadm bootstrap
  # (~/.config/yadm/bootstrap), not declared here.
  # ============================================================
  services.flatpak.enable = true;

  # Register flathub via a bootstrap unit. Two failure modes from the
  # original version are fixed here:
  #
  #   1. The ConditionPathExists = "!/var/lib/flatpak/repo/config" gate.
  #      A failed first-boot run still creates that repo config dir, so the
  #      condition became permanently unmet and the unit was skipped on every
  #      later boot — leaving flathub unregistered and every install failing
  #      with `No remote refs found for 'flathub'`. Dropped entirely;
  #      `remote-add --if-not-exists` is already idempotent.
  #
  #   2. The DNS race. network-online.target can be reached before name
  #      resolution actually works, so remote-add failed with "Could not
  #      resolve hostname". Restart=on-failure retries until DNS is up.
  systemd.services.flatpak-repo = {
    description = "Register Flathub as a flatpak remote (bootstrap)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "flatpak-system-helper.service" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Retry until DNS resolves, rather than failing permanently on a
      # transient first-boot network race.
      Restart = "on-failure";
      RestartSec = "15s";
    };
  };
}
