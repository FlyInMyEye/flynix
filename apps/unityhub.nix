{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.unityhub ];

      xdg.desktopEntries.unityhub = {
        name = "Unity Hub";
        exec = "env -u WAYLAND_DISPLAY unityhub %U";
        icon = "unityhub";
        categories = [ "Development" ];
        mimeType = [ "x-scheme-handler/unityhub" ];
        terminal = false;
      };
    })
  ];
}
