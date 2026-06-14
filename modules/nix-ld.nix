{ pkgs, ... }:
{
  # ============================================================
  # nix-ld: lets dynamically-linked binaries built for FHS distros
  # find their interpreter on NixOS. Required for:
  #   - SDKMAN-installed Java/Maven (yadm bootstrap 60-linux-manual.sh)
  #   - JetBrains Toolbox + IDEs
  #   - any third-party Linux binary that hard-codes /lib64/ld-linux*
  #
  # Without this, those tools fail at exec with "No such file or directory".
  # ============================================================
  programs.nix-ld.enable = true;

  # Common runtime libs those binaries expect. Add more as you hit them.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
    libxml2

    # X11 client libs: the JetBrains Toolbox bundled JRE links libawt_xawt.so
    # against these to draw its window. Missing them makes Toolbox launch but
    # show no window (AWTError: Failed to initialize the window toolkit:
    # libX11.so.6: cannot open shared object file).
    libx11
    libxext
    libxi
    libxrender
    libxtst
  ];
}
