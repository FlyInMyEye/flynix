{ ... }:

rec {
  userConfig = {
    username = "archbtw";
    fullName = "Jacopo Soria";
    email = "user@example.com";
    homeDirectory = "/home/${userConfig.username}";
  };

  bootConfig = {
    efiMountPoint = "/boot";
    resumeDevice = "/dev/disk/by-label/NIXROOT";
    resumeOffset = 39788544;
    grubTimeout = 0;
    hibernate.enable = true;
  };

  hardwareConfig = {
    swapFile = {
      enable = true;
      device = "/var/lib/swapfile";
      sizeMiB = 22 * 1024;
    };
    hpWirelessHotkeyWorkaround = true;
    ignoreLidSwitch = true;
    graphics = {
      enable32Bit = true;
      videoDrivers = [ "amdgpu" "nvidia" ];
      nvidiaPrime = {
        enable = true;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:5:0:0";
      };
    };
  };

  uxConfig = {
    monitor = [
      "eDP-1, 1920x1080@60.01Hz, 1920x0, 1"
    ];
    terminal = "kitty";
    browser = "firefox";
    fileManager = "nemo";
    menu = "qs ipc -p ${userConfig.homeDirectory}/.config/quickshell call island launcher";
    cursorTheme = "WhiteSur-cursors";
    cursorSize = 24;
    screenshotDirectory = "${userConfig.homeDirectory}/Screenshots";
    autostart = [
      "hypridle"
      "ibus-daemon -drx"
      "[workspace 1 silent] kitty"
      "[workspace 2 silent] firefox"
    ];
  };
}
