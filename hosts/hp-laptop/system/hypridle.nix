{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "island-lock";
            inhibit_sleep = 3;
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            {
              timeout = 240;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = 240;
              on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
              on-resume = "brightnessctl -rd rgb:kbd_backlight";
            }
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
          ];
        };
      };
    })
  ];
}
