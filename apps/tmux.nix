{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      programs.tmux = {
        enable = true;
        terminal = "tmux-256color";
        shell = "${pkgs.zsh}/bin/zsh";
        mouse = true;
        baseIndex = 1;
        escapeTime = 0;
        historyLimit = 10000;
        keyMode = "vi";
        plugins = with pkgs.tmuxPlugins; [
          nord
        ];
        prefix = "C-Space";
        extraConfig = ''
          set -ag terminal-overrides ",xterm-256color:RGB"

          # Start nvim in the first window on new session
          new-session -d -s main -n nvim 'nvim'
          new-window
          select-window -t 1
        '';
      };
    })
  ];
}
