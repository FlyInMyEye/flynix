{ inputs, lib, pkgs, bootConfig, ... }:

let
  resumeParams = lib.optionals (bootConfig.resumeDevice != null) (
    lib.optionals (bootConfig.resumeOffset != null) [
      "resume_offset=${toString bootConfig.resumeOffset}"
    ]
  );
in

{
  boot.loader = {
    systemd-boot.enable = false;
    timeout = bootConfig.grubTimeout;
    grub.useOSProber = true;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = bootConfig.efiMountPoint;
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

  boot.resumeDevice = lib.mkIf (bootConfig.resumeDevice != null) bootConfig.resumeDevice;
  boot.kernelParams = resumeParams ++ [
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
