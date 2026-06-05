{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  # Define user accounts.
  users.users.archbtw = {
    isNormalUser = true;
    description = "Jacopo Soria";
    extraGroups = [ "networkmanager" "wheel" "dialout" "uucp" "input" "ydotool" "storage" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Sets trusted users
  nix.settings.trusted-users = [ "root" "archbtw"];
}
