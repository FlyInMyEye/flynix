{ pkgs, ... }:

{
  networking.networkmanager.enable = true;

  services.resolved = {
    enable = true;
    settings.Resolve = {
      FallbackDNS = [ "1.1.1.1" "8.8.8.8" "1.0.0.1" "8.8.4.4" ];
      DNSStubListener = true;
      Cache = true;
      CacheFromLocalhost = true;
      DNSOverTLS = "opportunistic";
    };
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  networking.networkmanager.wifi.powersave = false;

  networking.networkmanager.settings = {
    main.dhcp = "internal";
    connection."wifi.powersave" = 2;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '';
}
