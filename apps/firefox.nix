{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  firefox-addons = inputs.nur.legacyPackages.${system}.repos.rycee.firefox-addons;
in {
  home-manager.sharedModules = [
    ({ ... }: {
      programs.firefox = {
        enable = true;
        configPath = ".mozilla/firefox";
        profiles."Original profile" = {
          id = 0;
          isDefault = true;
          path = "Original profile";
          extensions.force = true;
        };
      };
    })
  ];
}
