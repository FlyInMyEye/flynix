{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }:
      let
        telegram-xwayland = pkgs.writeShellScriptBin "telegram-desktop" ''
          unset WAYLAND_DISPLAY
          exec ${pkgs.telegram-desktop}/bin/telegram-desktop "$@"
        '';
      in {
        home.packages = [ telegram-xwayland ];

        xdg.desktopEntries.telegramdesktop = {
          name = "Telegram Desktop";
          exec = "telegram-desktop -- %u";
          icon = "telegram";
          terminal = false;
          categories = [ "Network" "InstantMessaging" "Qt" ];
          mimeType = [ "x-scheme-handler/tg" ];
        };
      })
  ];
}
