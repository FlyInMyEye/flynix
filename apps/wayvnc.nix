{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      systemd.user.services.wayvnc = {
        Unit = {
          Description = "Wayvnc VNC server for Wayland";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.wayvnc}/bin/wayvnc -C %h/.config/wayvnc/config";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    })
  ];
}
