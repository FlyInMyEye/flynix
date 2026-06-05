{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "never";
        settings = {
          program_options.udisks_version = 2;
          device_config = [
            {
              id_type = "ntfs";
              automount = true;
              mount_options = [ "force" ];
            }
            {
              id_type = "*";
              automount = true;
            }
          ];
        };
      };
    })
  ];
}
