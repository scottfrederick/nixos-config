{
  description = "sfrederick's NixOS configurations (home-hpone + work-dell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
      };
    };
}
