{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }:
      let
        wallpaper = "${../wallpapers/this-wallpaper-is-not-available.png}";
      in {
        services.hyprpaper = {
          enable = true;
          settings = {
            preload = [ wallpaper ];
            wallpaper = [
              {
                monitor = "";
                path = wallpaper;
                fit_mode = "cover";
              }
            ];
            splash = false;
          };
        };
      })
  ];
}
