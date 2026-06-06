{ pkgs, inputs }:

let
  dir = ./.;
  entries = builtins.readDir dir;
  packageFiles = builtins.map
    (name: dir + "/${name}")
    (builtins.filter
      (name:
        name != "_default.nix"
        && entries.${name} == "regular"
        && pkgs.lib.hasSuffix ".nix" name)
      (builtins.attrNames entries));
in
builtins.foldl'
  (acc: file: acc // (import file { inherit pkgs inputs; }))
  {}
  packageFiles
