{ lib, ... }:

let
  dir = ./.;
  entries = builtins.readDir dir;
  modules = builtins.map
    (name: dir + "/${name}")
    (builtins.filter
      (name:
        name != "_default.nix"
        && entries.${name} == "regular"
        && lib.hasSuffix ".nix" name)
      (builtins.attrNames entries));
in
{
  imports = modules;
}
