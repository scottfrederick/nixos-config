{
  lib,
  python3Packages,
  fetchFromGitHub,
  qt5,
  copyDesktopItems,
  makeDesktopItem,
}:

# ============================================================
# PlanetarySystemStacker (PSS) — lucky-imaging stacker for
# planetary/lunar/solar videos (AVI/SER). Not in nixpkgs.
#
# Pinned to an upstream master commit: setup.py there is 0.9.9
# and has dropped the old `numpy<1.23` pin, so it runs on the
# current nixpkgs numpy 2.x / Python 3.13. The last PyPI
# release (0.9.8.3) still has the pin and would not build.
# ============================================================
python3Packages.buildPythonApplication {
  pname = "planetary-system-stacker";
  version = "0.9.9-unstable-2026-09-25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Rolf-Hempel";
    repo = "PlanetarySystemStacker";
    rev = "26e94be05612fce012d1bc0b25930d57232aab17";
    hash = "sha256-Tr8TX7lUqq+4JGokk/990gzcZ3pXY9FlQR57JtYCVoQ=";
  };

  build-system = [ python3Packages.setuptools ];

  nativeBuildInputs = [
    qt5.wrapQtAppsHook
    copyDesktopItems
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtwayland
  ];

  dependencies = with python3Packages; [
    numpy
    matplotlib
    psutil
    pyqt5
    scipy
    astropy
    scikit-image
    opencv4
    pip # imported at runtime to report its version
  ];

  # nixpkgs' opencv4 doesn't ship `opencv-python` dist metadata.
  pythonRemoveDeps = [ "opencv-python" ];

  # Let the Python wrapper carry the Qt plugin paths.
  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  # Upstream has no test suite.
  doCheck = false;
  pythonImportsCheck = [ "planetary_system_stacker" ];

  desktopItems = [
    (makeDesktopItem {
      name = "planetary-system-stacker";
      desktopName = "PlanetarySystemStacker";
      comment = "Stack planetary, lunar and solar video captures";
      exec = "PlanetarySystemStacker";
      icon = "planetary-system-stacker";
      categories = [ "Graphics" "Science" "Astronomy" ];
    })
  ];

  postInstall = ''
    install -Dm644 planetary_system_stacker/PSS-Icon-64.png \
      $out/share/icons/hicolor/64x64/apps/planetary-system-stacker.png
  '';

  meta = {
    description = "Lucky-imaging stacker for planetary, lunar and solar video";
    homepage = "https://github.com/Rolf-Hempel/PlanetarySystemStacker";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "PlanetarySystemStacker";
  };
}
