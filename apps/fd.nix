{ lib, pkgs, ... }:

let
  bypassNames = [ "activate" "activation-script" "boot.json" "builder.pl" "dry-activate" "dummy-fc-dir1" "dummy-fc-dir2" "dummy-xdg-mime-dirs1" "dummy-xdg-mime-dirs2" "ensure-all-wrappers-paths-exist" "etc" "hm-firefox-extensions" "hm_hmfontconfigfonts.xml" "home-manager-files" "home-manager-generation" "home-manager-path" "kvantum-themes" "libxml2+py-2.15.3" "nixos-system-hp-laptop-26.11.20260711.e7a3ca8" "perl-5.42.0-env" "pythonGen" "stage-2-init.sh" "system-units" "unit-console-getty.service-disabled" "unit-home-manager-archbtw.service" "unit-pipewire-pulse.service-disabled" "unit-pipewire-pulse.socket-disabled" "unit-pipewire.service-disabled" "unit-pipewire.socket-disabled" "unit-wireplumber.service-disabled" "user-environment" "xdg-autostart-entries" ];
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
        (lib.attrByPath (lib.splitString "." "fd") null uncheckedPkgs)
      ];
    })
  ];
}
