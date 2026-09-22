{ pkgs, inputs, ... }:

{
  nixui = pkgs.rustPlatform.buildRustPackage {
    pname = "nixui";
    version = "0.1.0";

    src = inputs.nixui-src;

    cargoLock.lockFile = "${inputs.nixui-src}/Cargo.lock";

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram $out/bin/nixui \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.git
          pkgs.inetutils
          pkgs.nh
          pkgs.nix
          pkgs.sudo
          pkgs.util-linux
        ]}
    '';

    meta = {
      description = "Terminal UI for managing this NixOS app set";
      mainProgram = "nixui";
    };
  };
}
