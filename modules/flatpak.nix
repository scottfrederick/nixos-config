{ pkgs, ... }:
{
  # ============================================================
  # Flatpak runtime + Flathub remote.
  # Source had 47 flatpaks (3 remotes: flathub system, flathub user, cosmic user).
  # Per classification, all flatpaks are preserve-verbatim (kept as flatpaks).
  #
  # After first boot, restore the flatpaks below. The cosmic remote
  # (COSMIC applets) is OMITTED — target is GNOME, applets are COSMIC-only.
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

  # VERBATIM: full source flatpak list (run these manually post-install):
  #   flatpak install -y flathub com.brave.Browser  # branch: stable
  #   flatpak install -y flathub com.slack.Slack  # branch: stable
  #   flatpak install -y flathub com.spotify.Client  # branch: stable
  #   flatpak install -y cosmic io.github.cosmic_utils.sysinfo-applet  # branch: master
  #   flatpak install -y cosmic io.github.cosmic_utils.weather-applet  # branch: master
  #   flatpak install -y flathub net.cozic.joplin_desktop  # branch: stable
  #   flatpak install -y flathub org.ferdium.Ferdium  # branch: stable
  #   flatpak install -y flathub org.freedesktop.Sdk.Extension.ziglang  # branch: 24.08
  #   flatpak install -y flathub org.gimp.GIMP  # branch: stable
  #   flatpak install -y flathub org.gimp.GIMP.HEIC  # branch: stable
  #   flatpak install -y flathub org.siril.Siril  # branch: stable
  #   flatpak install -y flathub org.winehq.Wine.DLLs.dxvk  # branch: stable-22.08
  #   flatpak install -y flathub org.winehq.Wine.gecko  # branch: stable-22.08
  #   flatpak install -y flathub org.winehq.Wine.mono  # branch: stable-22.08
  #   flatpak install -y flathub us.zoom.Zoom  # branch: stable
}
