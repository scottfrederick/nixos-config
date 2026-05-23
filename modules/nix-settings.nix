{ ... }:
{
  # ============================================================
  # Nix daemon settings. Source had Nix 2.31.2 multi-user
  # alongside Pop!_OS; NixOS provides this natively.
  # ============================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
