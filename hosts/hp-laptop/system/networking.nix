{ pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" ];
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSStubListener = true;
      Cache = true;
      CacheFromLocalhost = true;
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
