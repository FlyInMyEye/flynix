{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "eucalyptus-drop";
    extraPackages = with pkgs.kdePackages; [
      qt6ct
      qtsvg
      qtdeclarative
      qt5compat
    ];
  };

  environment.systemPackages = [
    pkgs.customPkgs.sddm-eucalyptus-drop
  ];
}
