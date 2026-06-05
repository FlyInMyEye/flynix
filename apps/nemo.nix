{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, lib, ... }: {
      home.packages = with pkgs; [
        nemo
      ];
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "nemo.desktop";
          "x-scheme-handler/file" = "nemo.desktop";
        };
      };
      home.activation.makeMimeAppsWritable = lib.hm.dag.entryAfter ["linkGeneration"] ''
        MIMEAPPS="$HOME/.config/mimeapps.list"
        if [ -L "$MIMEAPPS" ]; then
          MIMEAPPS_TARGET=$(readlink -f "$MIMEAPPS")
          $DRY_RUN_CMD rm -f "$MIMEAPPS"
          $DRY_RUN_CMD cp -f "$MIMEAPPS_TARGET" "$MIMEAPPS"
          $DRY_RUN_CMD chmod u+w "$MIMEAPPS"
        fi
      '';
    })
  ];
}
