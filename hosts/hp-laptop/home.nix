{ config, pkgs, inputs, userConfig, ... }:

{
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.nix4nvchad.homeManagerModules.default
  ];

  home = { 
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;
    stateVersion = "24.05";
  };

  home.packages = with pkgs; [
    dconf
  ];

  home.sessionVariables = {
    TERMINAL = "kitty";
    EDITOR = "nvim";
    VISUAL = "nvim";
    HYPRSHOT_DIR = "${userConfig.homeDirectory}/Screenshots";

  };

  programs.home-manager.enable = true;

  programs.nvchad = {
    enable = true;
    backup = false;
  };
}
