{ pkgs, ... }:
let
  # Stellarium straight from nixpkgs, with one tweak: its window
  # reports the class "stellarium", but the launcher is named
  # org.stellarium.Stellarium.desktop, so the dock can't match them
  # and shows a generic gear icon. Add StartupWMClass so it matches.
  # symlinkJoin swaps in just the .desktop file (no source rebuild).
  stellarium = pkgs.symlinkJoin {
    name = "stellarium-${pkgs.stellarium.version}";
    paths = [ pkgs.stellarium ];
    postBuild = ''
      desktop=share/applications/org.stellarium.Stellarium.desktop
      rm "$out/$desktop"
      sed '/^\[Desktop Entry\]/a StartupWMClass=stellarium' \
        "${pkgs.stellarium}/$desktop" > "$out/$desktop"
    '';
  };
in
{
  # ============================================================
  # Astrophotography processing tools (home-hpone only).
  #
  # PSS and ImPPG aren't in nixpkgs, so both are packaged locally
  # under pkgs/. Stellarium comes straight from nixpkgs. Siril is
  # installed as a flatpak by the yadm bootstrap
  # (~/.setup/flatpak/siril.sh), not here.
  #
  #   PlanetarySystemStacker — stack planetary AVI/SER captures
  #   ImPPG                  — sharpen the stacked result
  #   Stellarium             — planetarium (identify moons, plan sessions)
  #
  # Workflow note: ImPPG is built without FreeImage (see its
  # package.nix), so have PSS save stacks as FITS.
  # ============================================================
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/planetary-system-stacker/package.nix { })
    (pkgs.callPackage ../pkgs/imppg/package.nix { })
    stellarium
  ];
}
