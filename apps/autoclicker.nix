{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = with pkgs; [
        ydotool
        zenity
        bc
      ];

      home.file.".local/bin/autoclicker".text = ''
        #!/usr/bin/env bash

        INTERVAL=$(zenity --entry --title="Autoclicker" --text="Enter click interval in milliseconds:" --entry-text="100")

        if [ -z "$INTERVAL" ]; then
            exit 0
        fi

        (
            echo "# Autoclicker is running..."
            echo "# Click interval: $INTERVAL ms"
            echo "# Press OK or close this window to stop"

            while true; do
                ydotool click 0xC0
                sleep $(echo "scale=3; $INTERVAL/1000" | bc)
            done
        ) | zenity --progress --title="Autoclicker Active" --text="Clicking..." --pulsate --auto-close --no-cancel &

        ZENITY_PID=$!
        wait $ZENITY_PID
      '';

      home.file.".local/bin/autoclicker".executable = true;
    })
  ];
}
