{ inputs, pkgs, themeConfig, ... }:

let
  wallpaper = themeConfig.desktopWallpaper;
  wallpaperName = builtins.baseNameOf (toString wallpaper);

  themes = {
    silent = {
      programs.silentSDDM = {
        enable = true;
        theme = themeConfig.sddm.silentPreset;
        backgrounds.default = wallpaper;
        settings = {
          LoginScreen.background = wallpaperName;
          LockScreen.background = wallpaperName;
        };
      };
    };
  };

  selectedTheme = themeConfig.sddm.theme;
  selectedThemeConfig = themes.${selectedTheme}
    or (throw "Unknown SDDM theme: ${selectedTheme}");
in
{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  services.displayManager.sddm.package = pkgs.kdePackages.sddm;

  services.displayManager.defaultSession = "hyprland";
}
// selectedThemeConfig
