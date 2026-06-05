{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nix4nvchad.homeManagerModule
  ];

  home = { 
    username = "archbtw";
    homeDirectory = "/home/archbtw";
    stateVersion = "24.05";
  };

  home.packages = with pkgs; [
    dconf
  ];

  home.sessionVariables = {
    TERMINAL = "kitty";
    EDITOR = "nvim";
    VISUAL = "nvim";
    HYPRSHOT_DIR = /home/archbtw/Screenshots;

  };

  programs.home-manager.enable = true;

  programs.nvchad = {
    enable = true;
    backup = false;
  };
}
