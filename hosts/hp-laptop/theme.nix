{ pkgs }:

rec {
  # Desktop background and the image used for Stylix's automatic palette.
  desktopWallpaper = ../../wallpapers/ign_chainsaw-man.png;
  # Set another image here to give the lock screen its own background.
  lockWallpaper = desktopWallpaper;

  stylix = {
    mode = "preset";
    preset = "nord";
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
