{ themeConfig, ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, lib, ... }: {
      stylix = {
        enable = true;
        image = themeConfig.wallpaper;
        opacity.terminal = 0.7;
        polarity = themeConfig.stylix.polarity;
        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.caskaydia-cove;
            name = "CaskaydiaCove Nerd Font Mono";
          };
          sizes.terminal = 14;
        };
        targets.firefox = {
          profileNames = [ "Original profile" ];
          colorTheme.enable = true;
        };
        # Explicitly disabled — they conflict or aren't wanted
        targets.hyprland.enable = false;
        targets.hyprlock.enable = false;
        targets.waybar.enable = false;
      } // lib.optionalAttrs (themeConfig.stylix.mode == "preset") {
        base16Scheme = themeConfig.stylix.presets.${themeConfig.stylix.preset};
      };

      gtk = {
        enable = true;
        iconTheme = {
          package = pkgs.kora-icon-theme;
          name = "kora-pgrey";
        };
      };

      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.whitesur-cursors;
        name = "WhiteSur-cursors";
        size = 24;
      };

      qt = {
        enable = true;
      };
    })
  ];
}
