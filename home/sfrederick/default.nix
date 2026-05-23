{ config, pkgs, lib, ... }:
{
  imports = [
    ./programs.nix
  ];

  home.username = "sfrederick";
  home.homeDirectory = "/home/sfrederick";
  home.stateVersion = "25.05";

  # ============================================================
  # CRITICAL: this Home Manager profile is INTENTIONALLY thin.
  # The user manages their dotfiles via `yadm` at
  #   https://github.com/scottfrederick/yadm
  # Per classification (yadm-instead), almost all of $HOME
  # config — .zshrc, zshrc.d/*.zsh, .gitconfig, .vimrc, plugin
  # manager (antidote), ghostty config, etc. — is restored by:
  #
  #   yadm clone https://github.com/scottfrederick/yadm
  #
  # Run this on first login. Do NOT also put these files
  # under home.file or programs.*.enable here — that would
  # create activation conflicts with yadm's checkout.
  # ============================================================

  # User-scoped packages that aren't system-wide
  home.packages = with pkgs; [
    yadm           # dotfiles manager — install first, then `yadm clone ...`
    # User-installed tools that yadm only stores config for (not the binaries):
    # SDKMAN, cargo, krew, go, zig, JetBrains Toolbox are all installed by
    # the user via their own installers (see MIGRATION_NOTES). Don't duplicate here.
  ];

  programs.home-manager.enable = true;
}
