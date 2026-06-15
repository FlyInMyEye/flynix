{ ... }:

{
  home-manager.sharedModules = [
    ({ config, ... }:
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        programs.rofi = {
          enable = true;
          modes = [ "drun" ];

          extraConfig = {
            show-icons = true;
            display-drun = "";
            drun-display-format = "{name}";
            sidebar-mode = false;
          };

          theme = {
            window = {
              border-radius = mkLiteral "5px";
              width = mkLiteral "50%";
              padding = mkLiteral "28px";
            };

            prompt = {
              enabled = true;
              padding = mkLiteral "0.5% 32px 0% 0%";
            };

            entry = {
              placeholder = "Search";
              expand = true;
              padding = mkLiteral "0.15% 0% 0% 0%";
            };

            inputbar = {
              children = map mkLiteral [ "prompt" "entry" ];
              expand = false;
              border-radius = mkLiteral "6px";
              margin = mkLiteral "0%";
              padding = mkLiteral "10px";
            };

            listview = {
              columns = 4;
              lines = 3;
              cycle = false;
              dynamic = true;
              layout = mkLiteral "vertical";
            };

            mainbox = {
              children = map mkLiteral [ "inputbar" "listview" ];
              spacing = mkLiteral "2%";
              padding = mkLiteral "2% 1% 2% 1%";
            };

            element = {
              orientation = mkLiteral "vertical";
              padding = mkLiteral "2% 0% 2% 0%";
            };

            element-icon = {
              size = mkLiteral "48px";
              horizontal-align = mkLiteral "0.5";
            };

            element-text = {
              expand = true;
              horizontal-align = mkLiteral "0.5";
              vertical-align = mkLiteral "0.5";
              margin = mkLiteral "0.5% 0.5% 0% 0.5%";
            };

            "element selected" = {
              border-radius = mkLiteral "6px";
            };
          };
        };
      })
  ];
}
