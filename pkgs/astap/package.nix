{
  lib,
  stdenv,
  fetchurl,
  unzip,
  icoutils,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  gtk2,
  glib,
  pango,
  cairo,
  gdk-pixbuf,
  atk,
  libx11,
  libjpeg8,
  openssl,
}:

# ============================================================
# ASTAP — Astrometric STAcking Program: offline plate solver,
# deep-sky annotation and FITS viewer. Used to plate-solve
# finished stacks without depending on VizieR (Siril's online
# catalogue fetch times out). Not in nixpkgs; repackages the
# upstream prebuilt GTK2 binary plus the D50 star database
# (5000 stars/sq deg, good for ~0.2–10° fields, ~900 MB).
#
# Upstream download URLs are NOT versioned: when hnsky.org
# publishes a new build the hashes stop matching. Re-prefetch
# and bump `version`:
#   nix store prefetch-file https://downloads.sourceforge.net/astap-program/linux_installer/astap_amd64.tar.gz
#   nix store prefetch-file https://downloads.sourceforge.net/astap-program/star_databases/d50_star_database.zip
# ============================================================
let
  d50 = fetchurl {
    url = "mirror://sourceforge/astap-program/star_databases/d50_star_database.zip";
    hash = "sha256-yompWMoICBhfDlRlQbSsc63cQP7krYvdi7eZgcHdi0M=";
  };
in
stdenv.mkDerivation {
  pname = "astap";
  version = "2026.11.12";

  src = fetchurl {
    url = "mirror://sourceforge/astap-program/linux_installer/astap_amd64.tar.gz";
    hash = "sha256-wQSYHWan7jZPAPm2QfgzQMcIBmMZjk4ywEVlu+46mVw=";
  };

  nativeBuildInputs = [
    unzip
    icoutils
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  # Libraries the GTK2 (Lazarus/LCL) binary links against.
  buildInputs = [
    gtk2
    glib
    pango
    cairo
    gdk-pixbuf
    atk
    libx11
    # unprocessed_raw-astap (bundled raw-file helper) wants libjpeg.so.8
    libjpeg8
  ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    mkdir -p prog db
    tar -xzf $src -C prog
    unzip -q ${d50} -d db
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Locate the main executable wherever the tarball puts it (opt/astap/ usually).
    bin=$(find prog -type f -name astap -perm -u+x | head -n1)
    if [ -z "$bin" ]; then
      echo "astap executable not found in tarball" >&2
      find prog >&2
      exit 1
    fi

    mkdir -p $out/opt/astap $out/bin
    # Program dir contents (executable, deep-sky catalogue, etc.)
    cp -r "$(dirname "$bin")"/. $out/opt/astap/
    # Star database next to the executable: ASTAP looks in its own
    # directory for the database when it isn't installed under /usr.
    find db -type f -exec cp {} $out/opt/astap/ \;
    chmod +x $out/opt/astap/astap

    # Icon: upstream only ships a Windows .ico, so split it into PNGs
    # and install each size into the hicolor theme. Sorted by bit depth
    # so the highest-depth image wins when a size appears twice.
    mkdir -p icons
    icotool -x -o icons prog/opt/astap/astap.ico
    for png in $(ls icons/*.png | sort -t x -k3 -n); do
      size=$(basename "$png" .png | sed -E 's/.*_([0-9]+)x([0-9]+)x[0-9]+$/\1x\2/')
      install -Dm644 "$png" "$out/share/icons/hicolor/$size/apps/astap.png"
    done

    # OpenSSL is loaded at runtime (online features), not linked.
    makeWrapper $out/opt/astap/astap $out/bin/astap \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ openssl ]}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "astap";
      exec = "astap %f";
      desktopName = "ASTAP";
      icon = "astap";
      # Lets the dock match the running window to this launcher.
      # GTK2 apps report WM_CLASS "astap" (instance) / "Astap" (class);
      # GNOME checks both against this value.
      startupWMClass = "astap";
      comment = "Astrometric plate solver, stacker and FITS viewer";
      categories = [
        "Science"
        "Astronomy"
      ];
      mimeTypes = [ "image/fits" ];
    })
  ];

  meta = {
    description = "Astrometric plate solver, stacking program and FITS viewer";
    homepage = "https://www.hnsky.org/astap.htm";
    license = lib.licenses.lgpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "astap";
  };
}
