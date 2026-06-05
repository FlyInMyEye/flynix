{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.nmap ];
    })
  ];
}
