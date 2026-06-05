{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.wineWow64Packages.staging ];
    })
  ];
}
