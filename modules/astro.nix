{ pkgs, ... }:
{
  # ============================================================
  # Astrophotography processing tools (home-hpone only).
  #
  # Neither is in nixpkgs, so both are packaged locally under
  # pkgs/. Siril is installed as a flatpak by the yadm bootstrap
  # (~/.setup/flatpak/siril.sh), not here.
  #
  #   PlanetarySystemStacker — stack planetary AVI/SER captures
  #   ImPPG                  — sharpen the stacked result
  #
  # Workflow note: ImPPG is built without FreeImage (see its
  # package.nix), so have PSS save stacks as FITS.
  # ============================================================
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/planetary-system-stacker/package.nix { })
    (pkgs.callPackage ../pkgs/imppg/package.nix { })
  ];
}
