{ config, pkgs, inputs, pkgs-stable, pkgs-unstable, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./system
    ../../apps/_default.nix
    inputs.home-manager.nixosModules.default 
  ];

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs pkgs-stable pkgs-unstable;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users = {
      "archbtw" = { 
        imports = [
          ../../hosts/hp-laptop/home.nix
        ];
      };
    };
  };

  nix.gc = {
    automatic = true;
    dates = "3days";
  };

  # Swap file for hibernation (22GB for 16GB RAM)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 22 * 1024; # 22GB in MB
  }];

  programs.hyprland.enable = true;
  virtualisation.podman.enable = true;

  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [ dconf ];
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  programs.ydotool.enable = true;

  # XDG Desktop Portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };

  # Power management
  services.power-profiles-daemon.enable = true;

  # HP laptops can emit bogus airplane-mode events on lid changes through this
  # vendor hotkey module, which then soft-blocks WiFi.
  boot.blacklistedKernelModules = [ "wireless_hotkey" ];

  # Keep system running when lid is closed
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  # Hybrid graphics: AMD iGPU drives display, NVIDIA dGPU is offload-only
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
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

      # From dmesg:
      # nvidia 0000:01:00.0
      # amdgpu 0000:05:00.0
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:5:0:0";
    };
  };

  # Enable SysRq keys for emergency recovery (Alt+SysRq+REISUB)
  boot.kernel.sysctl = {
    "kernel.sysrq" = 244; # Enable safe SysRq functions (sync, remount-ro, reboot, poweroff, show tasks)
    # Increase inotify limits for IntelliJ IDEA and other IDEs
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
    # Reduce aggressive swapping during high I/O (IDEA rebuilds)
    "vm.swappiness" = 10;
    # Keep more cache for better performance during builds
    "vm.vfs_cache_pressure" = 50;
    # TCP keep-alive settings to maintain connections during high load
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;
    # Increase network buffer sizes for better stability
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  # Session variables for Wayland / Hyprland
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  

  # Persistent environment variables for Minecraft / Java / Rust winit
  environment.variables = {
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    PATH = "${pkgs.jdk17}/bin:${builtins.getEnv "PATH"}";

    # Force Java to use XWayland for better compatibility (fixes file dialogs)
    _JAVA_AWT_WM_NONREPARENTING = "1";
    AWT_TOOLKIT = "MToolkit";
  };

  # Sudo rules for battery management (no password for power management)
  # Only allow tee to write to specific CPU power management files
  security.sudo.extraRules = [{
    users = [ "archbtw" ];
    commands = [
      { command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/nvidia-smi"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/nvidia-settings"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # System packages
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

  # Enable nix-ld for running dynamically linked binaries (like Rust cargo binaries)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libx11
    libxcursor
    libxrandr
    libxi
    libxkbcommon
    wayland
    libGL
    libglvnd
  ];

  services.flatpak.enable = true;

  systemd.services.flatpak-config = {
    description = "Configure Flatpak remotes";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "flatpak-config" ''
        if ${pkgs.flatpak}/bin/flatpak remotes --system --columns=name | ${pkgs.gnugrep}/bin/grep -qx flathub; then
          exit 0
        fi

        if ! ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
          printf '%s\n' 'flatpak-config: could not add flathub right now; retry after network is up.' >&2
          exit 0
        fi
      '';
    };
  };

  services.openssh.enable = false;
  services.printing.enable = true;

  # Tailscale for remote access through DS-Lite
  services.tailscale.enable = true;

  # Wayvnc for remote desktop access to Hyprland
  networking.firewall.allowedTCPPorts = [ 5900 ];

  system.stateVersion = "24.11"; # Do not change
}
