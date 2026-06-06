{
  description = "flynix flake UwU";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
 
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";

    sddm-eucalyptus-drop = {
      url = "gitlab:Matt.Jolly/sddm-eucalyptus-drop";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, nixpkgs-stable, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            customPkgs = import ./pkgs/_default.nix { pkgs = final; inherit inputs; };
          })
        ];
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "ciscoPacketTracer9-9.0.0"
            "dotnet-sdk-6.0.428"
            "dotnet-runtime-6.0.36"
            "electron-36.9.5"
          ];
        };
      };
    in {
      nixosConfigurations = {
        hp-laptop = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit inputs pkgs-stable;
            pkgs-unstable = pkgs;
          };
          modules = [
            ./hosts/hp-laptop/configuration.nix
            inputs.home-manager.nixosModules.default
          ];
        };

      };
    };
}
