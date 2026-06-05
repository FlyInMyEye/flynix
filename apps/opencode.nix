{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs-unstable, ... }: {
      home.packages = [ pkgs-unstable.opencode ];
    })
  ];
}
