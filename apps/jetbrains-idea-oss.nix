{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.jetbrains.idea-oss ];
    })
  ];
}
