{
  description = "sfrederick's NixOS configurations (home-hpone + work-dell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # Factor out the boilerplate so adding a third host is one line.
      mkHost = hostPath: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          hostPath
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sfrederick = import ./home/sfrederick;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    in {
      nixosConfigurations = {
        home-hpone = mkHost ./hosts/home-hpone/default.nix;
        work-dell  = mkHost ./hosts/work-dell/default.nix;

        # Test-only variant used by Phase 4 (artifacts/validation-report.json).
        # Adds autologin + a oneshot smoketest service that writes /tmp/xchg/smoketest.txt
        # and powers off. NOT for daily use.
        home-hpone-smoketest = mkHost ./hosts/home-hpone/vm-smoketest.nix;

        # home-hpone-usb: same config as home-hpone, but configured to boot from
        # an external USB drive (canTouchEfiVariables=false, USB modules in initrd,
        # distinct hostname). Use this to try-before-you-commit on the real
        # hardware without disturbing the source Pop install on the internal disk.
        home-hpone-usb = mkHost ./hosts/home-hpone/external.nix;
      };
    };
}
