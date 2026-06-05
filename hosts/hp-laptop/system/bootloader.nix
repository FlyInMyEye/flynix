{ inputs, config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = false;
    timeout = 0;
    grub.useOSProber = true;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      theme = inputs.nixos-grub-themes.packages.${pkgs.stdenv.hostPlatform.system}.hyperfluent;
      extraConfig = ''
        # Hide GRUB menu completely when timeout is 0
        set timeout_style=hidden
      '';
    };
  };

  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";
  boot.kernelParams = [
    "resume=/dev/disk/by-label/NIXROOT"
    "resume_offset=39788544"
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];

  boot.plymouth = {
    enable = true;
    theme = "deadlight";
    themePackages = [ pkgs.customPkgs.plymouth-deadlight ];
  };

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
}
