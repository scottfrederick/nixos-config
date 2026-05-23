{ ... }:
{
  # ============================================================
  # No programs.* modules enabled here on purpose.
  #
  # The user's $HOME is owned by yadm (cloned from
  # https://github.com/scottfrederick/yadm). That repo tracks
  # .zshrc, .zshenv, .bashrc, .gitconfig, .vimrc, .config/ghostty,
  # zshrc.d/*.zsh (antidote plugins), and ~80 other files.
  #
  # Enabling Home Manager modules like programs.zsh, programs.bash,
  # or programs.git — even with no settings under them — causes HM
  # to write minimal rc files (~/.zshrc, ~/.bashrc, ~/.config/git/config)
  # that collide with yadm's tracked copies. `nixos-rebuild switch`
  # then aborts with "Existing file ... is in the way".
  #
  # System-side wiring lives in modules/users.nix and modules/base.nix:
  #   - programs.zsh.enable = true   (NixOS — adds /etc/shells entry,
  #                                   loads global zsh init for login)
  #   - users.users.sfrederick.shell = pkgs.zsh
  #   - git, vim, etc. in environment.systemPackages
  #
  # That's enough to let yadm's dotfiles do their job. Don't add
  # programs.* here without verifying it doesn't write into a path
  # yadm tracks.
  #
  # If you want a *binary* (not config), add it to home.packages in
  # default.nix — that installs into the HM profile under
  # ~/.nix-profile/bin and doesn't touch $HOME config paths.
  # ============================================================

  # Intentionally empty.
}
