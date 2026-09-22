{
  description = "flynix flake UwU";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-freecad.url = "github:nixos/nixpkgs/0e251e24a4f24e036a084b6b4b2d2491af4167f4";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
 
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";

    nixui-src = {
      url = "github:FlyInMyEye/nixui";
      flake = false;
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    winapps = {
      url = "path:/home/archbtw/FreshASF/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixpkgs-stable, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            customPkgs = import ./pkgs/_default.nix { pkgs = final; inherit inputs; };
            freecad = inputs.nixpkgs-freecad.legacyPackages.${system}.freecad;
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
      themeConfig = import ./hosts/hp-laptop/theme.nix { inherit pkgs; };
      hostSettings = import ./hosts/hp-laptop/settings.nix { };
      inherit (hostSettings) userConfig bootConfig hardwareConfig uxConfig;
    in {
      nixosConfigurations = {
        hp-laptop = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit inputs pkgs-stable themeConfig userConfig bootConfig hardwareConfig uxConfig;
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
