{ pkgs, ... }:
let
  # Stellarium straight from nixpkgs, with one tweak: on Wayland its
  # window reports the app ID "org.stellarium." (Qt builds it from the
  # org domain + the executable's base name, and the NixOS wrapper's
  # binary is ".stellarium-wrapped", whose base name is empty). That
  # doesn't match org.stellarium.Stellarium.desktop, so the dock shows
  # a generic gear icon. StartupWMClass tells the dock to match them.
  # symlinkJoin swaps in just the .desktop file (no source rebuild).
  stellarium = pkgs.symlinkJoin {
    name = "stellarium-${pkgs.stellarium.version}";
    paths = [ pkgs.stellarium ];
    postBuild = ''
      desktop=share/applications/org.stellarium.Stellarium.desktop
      rm "$out/$desktop"
      sed '/^\[Desktop Entry\]/a StartupWMClass=org.stellarium.' \
        "${pkgs.stellarium}/$desktop" > "$out/$desktop"
    '';
  };
in
{
  # ============================================================
  # Astrophotography processing tools (home-hpone only).
  #
  # PSS, ImPPG and ASTAP aren't in nixpkgs, so they're packaged locally
  # under pkgs/. Stellarium comes straight from nixpkgs. Siril is
  # installed as a flatpak by the yadm bootstrap
  # (~/.setup/flatpak/siril.sh), not here.
  #
  #   PlanetarySystemStacker — stack planetary AVI/SER captures
  #   ImPPG                  — sharpen the stacked result
  #   ASTAP                  — offline plate solving + annotation
  #   Stellarium             — planetarium (identify moons, plan sessions)
  #
  # Workflow note: ImPPG is built without FreeImage (see its
  # package.nix), so have PSS save stacks as FITS.
  # ============================================================
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/planetary-system-stacker/package.nix { })
    (pkgs.callPackage ../pkgs/imppg/package.nix { })
    (pkgs.callPackage ../pkgs/astap/package.nix { })
    stellarium
  ];
}
