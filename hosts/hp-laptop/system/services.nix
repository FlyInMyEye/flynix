{ ... }:

{
  virtualisation.podman.enable = true;

  services.openssh.enable = false;
  services.printing.enable = true;
  services.tailscale.enable = true;

  networking.firewall.allowedTCPPorts = [ 5900 ];
}
