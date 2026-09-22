{ lib, pkgs, ... }:

let
  bypassNames = [ "activate" "etc" "freecad-1.1.1" "gdal-minimal-3.13.1" "hm_hmfontconfigfonts.xml" "home-manager-files" "home-manager-generation" "home-manager-path" "nixos-system-hp-laptop-26.11.20260711.e7a3ca8" "pdal-2.9.3" "system-units" "unit-home-manager-archbtw.service" "user-environment" "vtk-9.5.2" ];
  uncheckedPkgs = pkgs.extend (
    final: prev: {
      stdenv = prev.stdenv // {
        mkDerivation =
          value:
          let
            package = prev.stdenv.mkDerivation value;
          in
          if builtins.elem package.name bypassNames then
            package.overrideAttrs (_: {
              doCheck = false;
              doInstallCheck = false;
            })
          else
            package;
      };
    }
  );
in
{
  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.packages = [
        (lib.attrByPath (lib.splitString "." "waydroid") null uncheckedPkgs)
      ];
    })
  ];
}
