{ pkgs, config, lib, userConfig, bootConfig, themeConfig, ... }:
let
  srcDir = "/etc/nixos/config/quickshell";
  islandLock = pkgs.writeShellApplication {
    name = "island-lock";
    runtimeInputs = [ pkgs.quickshell ];
    text = ''
      configPath=${lib.escapeShellArg "${userConfig.homeDirectory}/.config/quickshell"}
      state="$(qs ipc -p "$configPath" call island status 2>/dev/null || true)"
      case "$state" in
        LOCKING) exit 0 ;;
        IDLE|HOVER_TIME|WORKSPACES|STATS|TRANSIENT|HARDWARE|TRAY|CLIPBOARD|LAUNCHER|WIFI|BLUETOOTH)
          qs ipc -p "$configPath" call island lock
          ;;
        *) exec qs --no-duplicate --path "$configPath/lock.qml" ;;
      esac
    '';
  };
  c = config.lib.stylix.colors;

  colorsJson = pkgs.writeText "quickshell-colors.json" (builtins.toJSON {
    inherit (c) base00 base01 base03 base05 base08 base0A base0B base0C base0D base0E;
    bg     = "#${c.base00}";
    fg     = "#${c.base05}";
    altBg  = "#${c.base01}";
    muted  = "#${c.base03}";
    accent = "#${c.base0D}";
    red    = "#${c.base08}";
    green  = "#${c.base0B}";
    yellow = "#${c.base0A}";
    blue   = "#${c.base0D}";
    cyan   = "#${c.base0C}";
    magenta = "#${c.base0E}";
    hibernationEnabled = bootConfig.hibernate.enable;
  });

  colorsQml = pkgs.writeText "quickshell-Colors.qml" ''
    import QtQuick
    import Quickshell.Io

    QtObject {
      id: colors

      property string bg: "#${c.base00}"
      property string fg: "#${c.base05}"
      property string altBg: "#${c.base01}"
      property string muted: "#${c.base03}"
      property string accent: "#${c.base0D}"
      property string red: "#${c.base08}"
      property string green: "#${c.base0B}"
      property string yellow: "#${c.base0A}"
      property string blue: "#${c.base0D}"
      property string cyan: "#${c.base0C}"
      property string magenta: "#${c.base0E}"
      property bool hibernationEnabled: ${if bootConfig.hibernate.enable then "true" else "false"}

      property string _lastJson: ""

      function updateColors(json) {
        try {
          var o = JSON.parse(json);
          if (o.bg) colors.bg = o.bg;
          if (o.fg) colors.fg = o.fg;
          if (o.altBg) colors.altBg = o.altBg;
          if (o.muted) colors.muted = o.muted;
          if (o.accent) colors.accent = o.accent;
          if (o.red) colors.red = o.red;
          if (o.green) colors.green = o.green;
          if (o.blue) colors.blue = o.blue;
          if (o.cyan) colors.cyan = o.cyan;
          if (o.magenta) colors.magenta = o.magenta;
          if (typeof o.hibernationEnabled === "boolean") colors.hibernationEnabled = o.hibernationEnabled;
        } catch (_) {}
      }

      Component.onCompleted: {
        var reader = Qt.createQmlObject(
          'import Quickshell.Io; import QtQml; Process { id: _p; property QtObject target: null; command: ["sh", "-c", "cat ''${HOME:-${userConfig.homeDirectory}}/.config/quickshell/colors.json"]; stdout: StdioCollector { onStreamFinished: { if (this.text !== _p.target._lastJson) { _p.target._lastJson = this.text; _p.target.updateColors(this.text); } } } }',
          colors, "colorReader"
        );
        reader.target = colors;
        Qt.createQmlObject(
          'import QtQuick; Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: parent.running = true }',
          reader, "colorTimer"
        );
      }
    }
  '';
in {
  environment.systemPackages = with pkgs; [
    python3 brightnessctl wireplumber cliphist wl-clipboard procps cava islandLock
  ];
  security.pam.services.quickshell-island = {};
  environment.etc."quickshell/lock-wallpaper".source = themeConfig.lockWallpaper;
  fonts.packages = with pkgs; [ redhat-official-fonts nerd-fonts.caskaydia-cove ];

  system.activationScripts.quickshellConfig = {
    text = ''
      configDir="${userConfig.homeDirectory}/.config/quickshell"
      rm -f "$configDir"
      ln -sfn ${lib.escapeShellArg srcDir} "$configDir"
      cp -f ${colorsJson} "${srcDir}/colors.json"
      cp -f ${colorsQml} "${srcDir}/Colors.qml"
    '';
    deps = [];
  };

  home-manager.sharedModules = [
    ({ ... }: {
      programs.quickshell = {
        enable = true;
        systemd.enable = true;
      };
    })
  ];
}
