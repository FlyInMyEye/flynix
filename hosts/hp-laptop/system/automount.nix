{ pkgs, ... }:

{
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.udisks2.settings = {
    "udisks2.conf" = {
      defaults = {
        encryption = "luks2";
      };
      udisks2 = {
        modules = [ "*" ];
        modules_load_preference = "ondemand";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    ntfs3g
  ];
}
