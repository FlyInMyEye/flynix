{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.github-desktop ];

      xdg.desktopEntries.github-desktop = {
        name = "GitHub Desktop";
        exec = "env GIT_EXEC_PATH=${pkgs.git}/libexec/git-core PATH=${pkgs.lib.makeBinPath [ pkgs.git ]} ${pkgs.github-desktop}/bin/github-desktop %U";
        icon = "github-desktop";
        categories = [ "Development" ];
        mimeType = [ "x-scheme-handler/x-github-client" "x-scheme-handler/x-github-desktop-auth" "x-scheme-handler/x-github-desktop-dev-auth" ];
        terminal = false;
      };
    })
  ];
}
