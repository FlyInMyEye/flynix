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
    image = themeConfig.wallpaper;
    polarity = stylixConfig.polarity;

    targets.kmscon.enable = false;

    # SilentSDDM owns the login theme configuration.
    targets.sddm.enable = false;
  };
}
// lib.optionalAttrs (stylixConfig.mode == "preset") {
  stylix.base16Scheme = presetScheme;
}
