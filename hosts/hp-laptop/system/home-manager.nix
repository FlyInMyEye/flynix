{ inputs, pkgs-stable, pkgs-unstable, themeConfig, userConfig, ... }:

{
  home-manager = {
    extraSpecialArgs = {
      inherit inputs pkgs-stable pkgs-unstable themeConfig userConfig;
    };
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.${userConfig.username} = {
      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "ciscoPacketTracer9-9.0.0"
          "dotnet-sdk-6.0.428"
          "dotnet-runtime-6.0.36"
          "electron-36.9.5"
        ];
      };
      imports = [ ../home.nix ];
    };
  };
}
