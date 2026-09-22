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
        profiles."Main profile" = {
          id = 0;
          isDefault = true;
          path = "ix82vo45.default";
          extensions.force = true;
          extensions.packages = with firefox-addons; [
            clearurls
            firefox-color
            privacy-badger
            ublock-origin
          ];
        };
      };
    })
  ];
}
