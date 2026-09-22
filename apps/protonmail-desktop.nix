{ lib, pkgs, ... }:

{
  home-manager.sharedModules = [
    ({ lib, pkgs, ... }: {
      home.packages = [
        (lib.attrByPath (lib.splitString "." "protonmail-desktop") null pkgs)
      ];
    })
  ];
}
