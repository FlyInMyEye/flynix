{ pkgs }:

let
  wallpaper = ../../wallpapers/this-wallpaper-is-not-available.png;
in
{
  wallpaper = wallpaper;

  stylix = {
    mode = "preset";
    preset = "dracula";
    polarity = "dark";
    presets = {
      nord = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      dracula = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
      gruvbox-dark-hard = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      catppuccin-mocha = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };
  };

  sddm = {
    theme = "silent";
    silentPreset = "rei";
  };
}
