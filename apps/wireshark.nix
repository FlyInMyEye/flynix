{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs-stable, ... }: {
      home.packages = [ pkgs-stable.wireshark ];
    })
  ];
}
