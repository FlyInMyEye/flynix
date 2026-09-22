{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libx11
    libxcursor
    libxrandr
    libxi
    libxkbcommon
    wayland
    libGL
    libglvnd
  ];
}
