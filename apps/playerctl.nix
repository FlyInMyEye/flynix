{ pkgs, ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      home.packages = with pkgs; [
        playerctl
      ];
    })
  ];
}
