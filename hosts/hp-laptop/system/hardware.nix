{ config, lib, hardwareConfig, ... }:

let
  cfg = hardwareConfig;
in
{
  swapDevices = lib.optionals cfg.swapFile.enable [
    {
      device = cfg.swapFile.device;
      size = cfg.swapFile.sizeMiB;
    }
  ];

  # Some HP laptops emit bogus airplane-mode events on lid changes through this
  # vendor hotkey module + hp_wmi driver, which soft-blocks WiFi on lid open.
  boot.blacklistedKernelModules = lib.optionals cfg.hpWirelessHotkeyWorkaround [
    "wireless_hotkey"
    "hp_wmi"
  ];

  services.logind.settings.Login = lib.mkIf cfg.ignoreLidSwitch {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  services.xserver.videoDrivers = cfg.graphics.videoDrivers;

  hardware.graphics = {
    enable = true;
    enable32Bit = cfg.graphics.enable32Bit;
  };

  hardware.nvidia = lib.mkIf cfg.graphics.nvidiaPrime.enable {
    modesetting.enable = true;
    open = false;
    nvidiaPersistenced = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      nvidiaBusId = cfg.graphics.nvidiaPrime.nvidiaBusId;
      amdgpuBusId = cfg.graphics.nvidiaPrime.amdgpuBusId;
    };
  };
}
