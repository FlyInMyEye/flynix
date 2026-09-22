{ inputs, lib, pkgs, themeConfig, ... }:

let
  stylixConfig = themeConfig.stylix;
  presetScheme = stylixConfig.presets.${stylixConfig.preset} or null;
in
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  assertions = [
    {
      assertion = builtins.elem stylixConfig.mode [ "auto" "preset" ];
      message = "themeConfig.stylix.mode must be either \"auto\" or \"preset\".";
    }
    {
      assertion = stylixConfig.mode != "preset" || presetScheme != null;
      message = "themeConfig.stylix.preset must exist in themeConfig.stylix.presets when mode = \"preset\".";
    }
  ];

  stylix = {
    enable = true;
    image = themeConfig.desktopWallpaper;
    polarity = stylixConfig.polarity;

    targets.kmscon.enable = false;

    # SilentSDDM owns the login theme configuration.
    targets.sddm.enable = false;
  };

  home-manager.sharedModules = [
    ({ pkgs, lib, ... }: {
      stylix = {
        enable = true;
        image = themeConfig.desktopWallpaper;
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
          profileNames = [ "Main profile" ];
          colorTheme.enable = true;
        };
        targets.hyprland.enable = false;
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

      qt.enable = true;
    })
  ];
}
// lib.optionalAttrs (stylixConfig.mode == "preset") {
  stylix.base16Scheme = presetScheme;
}
