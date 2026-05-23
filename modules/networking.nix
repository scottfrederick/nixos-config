{ config, pkgs, lib, ... }:
{
  # ============================================================
  # NetworkManager (matches source: 13 saved NM connections).
  #
  # WiFi/VPN credentials in /etc/NetworkManager/system-connections
  # were not readable without root during inventory. Either:
  #   (a) re-enter passwords on first login, or
  #   (b) copy /etc/NetworkManager/system-connections/* from the
  #       old machine into /etc/NetworkManager/system-connections/
  #       on the new one (do this manually after first boot).
  # ============================================================
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";   # REVIEW: switch to "wpa_supplicant" if you hit driver issues
  };

  # Source had ModemManager enabled (for mobile broadband / WWAN).
  networking.modemmanager.enable = lib.mkDefault true;

  # Default firewall — was unreadable on source (ufw status needed root);
  # Pop's default is ufw inactive, but NixOS's default firewall is on with
  # no open ports, which is the safer baseline.
  networking.firewall = {
    enable = true;
    # Open these only if you actually run servers locally — add explicitly here.
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # /etc/hosts: source had only the default 127.0.0.1 + ::1 + Pop's 127.0.1.1.
  # NixOS adds the right entries automatically from networking.hostName.
}
