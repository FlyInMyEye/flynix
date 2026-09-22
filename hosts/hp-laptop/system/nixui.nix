{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.customPkgs.nixui ];
}
