{ pkgs, ... }:
{
  # ============================================================
  # 1Password — uses the dedicated NixOS module (sets up
  # the setuid helper + polkit + browser integration).
  # Replaces the apt repo at downloads.1password.com.
  # ============================================================
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "sfrederick" ];
  };
}
