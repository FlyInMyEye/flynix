{ inputs, pkgs, ... }:

let
  wallpaper = ../../../wallpapers/this-wallpaper-is-not-available.png;
  wallpaperName = builtins.baseNameOf (toString wallpaper);

  themes = {
    silent = {
      programs.silentSDDM = {
        enable = true;
        theme = "rei";
        backgrounds.default = wallpaper;
        settings = {
          LoginScreen.background = wallpaperName;
          LockScreen.background = wallpaperName;
        };
      };
    };
  };

  selectedTheme = "silent";
  selectedThemeConfig = themes.${selectedTheme}
    or (throw "Unknown SDDM theme: ${selectedTheme}");
in
{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
}
// selectedThemeConfig
