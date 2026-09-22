{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "3days";
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    git-lfs
    home-manager
    nix-prefetch
    nix-prefetch-github
    os-prober
  ];
}
