{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  wrapGAppsHook3,
  copyDesktopItems,
  makeDesktopItem,
  boost,
  wxwidgets_3_2,
  glew,
  libGL,
  cfitsio,
  lua5_4,
}:

# ============================================================
# ImPPG — Image Post-Processor (deconvolution, unsharp mask,
# tone curve) for stacked planetary/lunar/solar images.
# Not in nixpkgs; built from the upstream release tag.
#
# Built WITHOUT FreeImage: FreeImage was removed from nixpkgs
# (2025-10) over unfixed CVEs. Without it ImPPG reads/writes
# FITS, BMP and *uncompressed* TIFF only — no PNG/JPEG, no
# LZW/ZIP-compressed TIFF. Save stacks from PSS as FITS.
# ============================================================
stdenv.mkDerivation (finalAttrs: {
  pname = "imppg";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "GreatAttractor";
    repo = "imppg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FQboo3sv7n4aQjSifihMgEwNFohCs7U4l9vLra7Umrk=";
  };

  postPatch = ''
    substituteInPlace config.cmake \
      --replace-fail "set(USE_FREEIMAGE 1)" "set(USE_FREEIMAGE 0)"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    boost
    wxwidgets_3_2
    glew
    libGL
    cfitsio
    lua5_4
  ];

  # Top-level CMakeLists declares `cmake_minimum_required(VERSION 2.8...3.5)`.
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  desktopItems = [
    (makeDesktopItem {
      name = "imppg";
      desktopName = "ImPPG";
      comment = "Post-process stacked astronomical images";
      exec = "imppg %F";
      icon = "imppg";
      categories = [ "Graphics" "Science" "Astronomy" ];
    })
  ];

  postInstall = ''
    install -Dm644 $src/images/imppg-app.png \
      $out/share/icons/hicolor/64x64/apps/imppg.png
  '';

  meta = {
    description = "Image post-processor for astronomical images (Lucy-Richardson deconvolution, unsharp masking)";
    homepage = "https://github.com/GreatAttractor/imppg";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "imppg";
  };
})
