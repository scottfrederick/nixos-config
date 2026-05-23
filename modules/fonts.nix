{ pkgs, ... }:
{
  # ============================================================
  # Fonts — covers the apt fonts-* the user had + CJK from
  # fonts-noto-cjk(-extra), arphic ukai/uming, plus sensible
  # defaults for a developer workstation.
  # ============================================================
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
      dejavu_fonts
      jetbrains-mono
      fira-code
      fira-code-symbols
      source-code-pro
      arphic-ukai
      arphic-uming
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "Noto Serif CJK SC" ];
        sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
        monospace = [ "JetBrains Mono" "Noto Sans Mono CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
