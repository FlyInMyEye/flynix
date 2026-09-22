{ userConfig, ... }:

{
  security.sudo.extraRules = [{
    users = [ userConfig.username ];
    commands = [
      { command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/nvidia-smi"; options = [ "NOPASSWD" ]; }
      { command = "/run/current-system/sw/bin/nvidia-settings"; options = [ "NOPASSWD" ]; }
    ];
  }];
}
