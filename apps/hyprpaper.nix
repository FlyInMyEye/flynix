{ themeConfig, ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
        services.hyprpaper.enable = true;
      })
  ];
}
