{ config, pkgs, lib, ... }:
{
  imports = [
    ./programs.nix
    ./gnome.nix
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

  # User-scoped packages. Intentionally empty:
  #   - yadm is installed system-wide via modules/base.nix; don't duplicate here.
  #   - User-installed toolchains (SDKMAN, cargo, krew, go, zig, JetBrains Toolbox)
  #     are installed by the user via their own installers (see MIGRATION_NOTES).
  home.packages = [ ];

  programs.home-manager.enable = true;
}
