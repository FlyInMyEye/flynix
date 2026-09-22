{ inputs, pkgs, config, themeConfig, ... }:

let
  wallpaper = themeConfig.desktopWallpaper;
  wallpaperName = builtins.baseNameOf (toString wallpaper);

  c = config.lib.stylix.colors;
  bg = "#${c.base00}";
  altBg = "#${c.base01}";
  muted = "#${c.base03}";
  fg = "#${c.base05}";
  red = "#${c.base08}";
  yellow = "#${c.base0A}";
  green = "#${c.base0B}";
  accent = "#${c.base0D}";
  font = "JetBrainsMono Nerd Font";
  mono = "JetBrainsMono Nerd Font Mono";

  islandStyle = {
    General = {
      scale = 1.0;
      "enable-animations" = true;
      "background-fill-mode" = "fill";
    };

    LockScreen = {
      display = true;
      background = wallpaperName;
      "use-background-color" = false;
      blur = 0;
      brightness = -0.18;
      saturation = 0.0;
      "input-keystroke" = false;
      "ignore-shift-key" = false;
    };

    "LockScreen.Clock" = {
      display = true;
      position = "center-left";
      align = "center";
      format = "hh:mm";
      "font-family" = mono;
      "font-size" = 96;
      "font-weight" = 300;
      color = fg;
    };

    "LockScreen.Date" = {
      display = true;
      format = "dddd, d MMMM";
      locale = "en_US";
      "font-family" = font;
      "font-size" = 14;
      "font-weight" = 400;
      color = muted;
      "margin-top" = -8;
    };

    "LockScreen.Message".display = false;

    LoginScreen = {
      background = wallpaperName;
      "use-background-color" = false;
      blur = 0;
      brightness = -0.18;
      saturation = 0.0;
    };

    "LoginScreen.LoginArea" = {
      position = "center";
      margin = 210;
    };

    "LoginScreen.LoginArea.Avatar" = {
      shape = "square";
      "border-radius" = 32;
      "active-size" = 64;
      "inactive-size" = 48;
      "inactive-opacity" = 0.35;
      "active-border-size" = 1;
      "inactive-border-size" = 1;
      "active-border-color" = accent;
      "inactive-border-color" = muted;
      "always-active" = true;
    };

    "LoginScreen.LoginArea.Username" = {
      "font-family" = font;
      "font-size" = 14;
      "font-weight" = 500;
      color = fg;
      margin = 8;
    };

    "LoginScreen.LoginArea.PasswordInput" = {
      width = 330;
      height = 52;
      "display-icon" = true;
      "font-family" = font;
      "font-size" = 14;
      "icon-size" = 18;
      "content-color" = fg;
      "background-color" = bg;
      "background-opacity" = 0.96;
      "border-size" = 1;
      "border-color" = accent;
      "border-radius-left" = 26;
      "border-radius-right" = 26;
      "margin-top" = 10;
      "masked-character" = "•";
    };

    "LoginScreen.LoginArea.LoginButton" = {
      "background-color" = altBg;
      "background-opacity" = 0.96;
      "active-background-color" = accent;
      "active-background-opacity" = 1.0;
      "icon-size" = 20;
      "content-color" = accent;
      "active-content-color" = bg;
      "border-size" = 1;
      "border-color" = accent;
      "border-radius-left" = 26;
      "border-radius-right" = 26;
      "margin-left" = 8;
      "show-text-if-no-password" = true;
      "hide-if-not-needed" = true;
      "font-family" = font;
      "font-size" = 12;
      "font-weight" = 500;
    };

    "LoginScreen.LoginArea.Spinner" = {
      "display-text" = true;
      text = "Logging in";
      "font-family" = font;
      "font-weight" = 500;
      "font-size" = 13;
      "icon-size" = 24;
      color = accent;
      spacing = 6;
    };

    "LoginScreen.LoginArea.WarningMessage" = {
      "font-family" = font;
      "font-size" = 12;
      "font-weight" = 400;
      "normal-color" = muted;
      "warning-color" = yellow;
      "error-color" = red;
      "margin-top" = 10;
    };

    "LoginScreen.MenuArea.Buttons" = {
      "margin-top" = 0;
      "margin-right" = 28;
      "margin-bottom" = 28;
      "margin-left" = 0;
      size = 38;
      "border-radius" = 19;
      spacing = 8;
      "font-family" = font;
    };

    "LoginScreen.MenuArea.Popups" = {
      "max-height" = 300;
      "item-height" = 34;
      "item-spacing" = 2;
      padding = 6;
      "display-scrollbar" = false;
      margin = 6;
      "background-color" = bg;
      "background-opacity" = 0.96;
      "active-option-background-color" = accent;
      "active-option-background-opacity" = 1.0;
      "content-color" = fg;
      "active-content-color" = bg;
      "font-family" = font;
      "border-size" = 1;
      "border-color" = accent;
      "font-size" = 11;
      "icon-size" = 16;
    };

    "LoginScreen.MenuArea.Session" = {
      display = true;
      position = "bottom-right";
      index = 4;
      "popup-direction" = "up";
      "popup-align" = "end";
      "display-session-name" = false;
      "button-width" = 38;
      "popup-width" = 220;
      "background-color" = bg;
      "background-opacity" = 0.88;
      "active-background-opacity" = 1.0;
      "content-color" = accent;
      "active-content-color" = fg;
      "border-size" = 0;
      "font-size" = 10;
      "icon-size" = 16;
    };

    "LoginScreen.MenuArea.Layout" = {
      display = true;
      position = "bottom-right";
      index = 3;
      "popup-direction" = "up";
      "popup-align" = "end";
      "popup-width" = 180;
      "display-layout-name" = false;
      "background-color" = bg;
      "background-opacity" = 0.88;
      "active-background-opacity" = 1.0;
      "content-color" = accent;
      "active-content-color" = fg;
      "border-size" = 0;
      "font-size" = 10;
      "icon-size" = 16;
    };

    "LoginScreen.MenuArea.Keyboard" = {
      display = true;
      position = "bottom-right";
      index = 2;
      "background-color" = bg;
      "background-opacity" = 0.88;
      "active-background-opacity" = 1.0;
      "content-color" = accent;
      "active-content-color" = fg;
      "border-size" = 0;
      "icon-size" = 16;
    };

    "LoginScreen.MenuArea.Power" = {
      display = true;
      position = "bottom-right";
      index = 1;
      "popup-direction" = "up";
      "popup-align" = "end";
      "popup-width" = 110;
      "background-color" = bg;
      "background-opacity" = 0.88;
      "active-background-opacity" = 1.0;
      "content-color" = accent;
      "active-content-color" = fg;
      "border-size" = 0;
      "icon-size" = 16;
    };

    "LoginScreen.VirtualKeyboard" = {
      scale = 1.0;
      position = "login";
      "start-hidden" = true;
      "background-color" = bg;
      "background-opacity" = 0.96;
      "key-content-color" = fg;
      "key-color" = altBg;
      "key-opacity" = 1.0;
      "key-active-background-color" = accent;
      "key-active-opacity" = 1.0;
      "selection-background-color" = accent;
      "selection-content-color" = bg;
      "primary-color" = accent;
      "border-size" = 1;
      "border-color" = muted;
      "restrict-input" = "none";
    };

    Tooltips = {
      enable = true;
      "font-family" = font;
      "font-size" = 11;
      "content-color" = fg;
      "background-color" = bg;
      "background-opacity" = 0.96;
      "border-radius" = 18;
      "disable-user" = false;
      "disable-login-button" = false;
    };
  };

  themes = {
    silent = {
      programs.silentSDDM = {
        enable = true;
        theme = themeConfig.sddm.silentPreset;
        backgrounds.default = wallpaper;
        settings = islandStyle;
      };
    };
  };

  selectedTheme = themeConfig.sddm.theme;
  selectedThemeConfig = themes.${selectedTheme}
    or (throw "Unknown SDDM theme: ${selectedTheme}");
in
{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
  services.displayManager.defaultSession = "hyprland";

  # Quickshell uses this family for the island and native lock screen. Install it
  # system-wide so the SDDM greeter renders the same typography before login.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
// selectedThemeConfig
