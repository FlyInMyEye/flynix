{ ... }:

{
  home-manager.sharedModules = [
    ({ config, pkgs, ... }: {
      gtk = {
        enable = true;
        theme = {
          package = pkgs.nordic;
          name = "Nordic";
        };
        gtk4.theme = config.gtk.theme;
        iconTheme = {
          package = pkgs.kora-icon-theme;
          name = "kora-pgrey";
        };
      };

      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.whitesur-cursors;
        name = "WhiteSur-cursors";
        size = 24;
      };

      qt = {
        enable = true;
        platformTheme.name = "qtct";
        style = {
          package = pkgs.nordic;
          name = "Nordic";
        };
      };
    })
  ];
}
