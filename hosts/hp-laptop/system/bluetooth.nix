{ pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        ControllerMode = "dual";
        Experimental = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    blueman
    bluez
    bluez-tools
  ];
}
