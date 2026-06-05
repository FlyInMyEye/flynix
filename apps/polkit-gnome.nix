{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.polkit_gnome ];
    })
  ];
}
