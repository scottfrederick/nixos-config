{ pkgs, ... }:
{
  # ============================================================
  # Flatpak runtime + Flathub remote.
  # This module only enables flatpak and registers the Flathub remote.
  # The actual flatpak app installs are handled by the yadm bootstrap
  # (~/.config/yadm/bootstrap), not declared here.
  # ============================================================
  services.flatpak.enable = true;

  # Add flathub on activation (not declarative; runs once if missing).
  # Must wait for network — otherwise the flatpak remote-add fails on
  # first boot because flathub.org isn't yet resolvable.
  systemd.services.flatpak-repo = {
    description = "Register Flathub as a flatpak remote (first-boot bootstrap)";
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
      # If the network never comes up (e.g. headless install with no NM
      # profiles yet), let the unit fail cleanly rather than wedging boot.
      TimeoutStartSec = "120s";
      # Don't block boot if this fails; the user can also run the
      # `flatpak remote-add` command manually.
    };
    unitConfig.ConditionPathExists = "!/var/lib/flatpak/repo/config";
  };
}
