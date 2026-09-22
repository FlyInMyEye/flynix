{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.brightnessctl ];
  security.wrappers.brightnessctl = {
    source = "${pkgs.brightnessctl}/bin/brightnessctl";
    setuid = true;
    owner = "root";
    group = "root";
    permissions = "u+rx,g+rx,o+rx";
  };
}
