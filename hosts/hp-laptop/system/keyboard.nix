{ pkgs, ... }:

{
  services.xserver.xkb = {
    layout = "us,pl,ru";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  console.keyMap = "us";

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      m17n
    ];
  };

  environment.systemPackages = with pkgs; [
    m17n_db
    m17n_lib
  ];

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        kpenter = "esc";
      };
    };
  };
}
