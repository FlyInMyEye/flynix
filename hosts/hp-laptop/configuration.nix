{ ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./system
    ../../apps/_default.nix
  ];

  system.stateVersion = "24.11"; # Do not change
}
