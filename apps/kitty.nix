{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      programs.kitty = {
        enable = true;
        shellIntegration.enableZshIntegration = true;
        keybindings = {
          "kp_multiply" = "send_text all \\x00";
        };
        settings = {
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";
          enable_audio_bell = false;
          confirm_os_windows_close = false;
          copy_on_select = true;
        };
      };
    })
  ];
}
