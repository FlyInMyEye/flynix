{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, pkgs-stable, ... }: {
      home.packages = [ pkgs-stable.github-desktop ];

      xdg.desktopEntries.github-desktop = {
        name = "GitHub Desktop";
        exec = "env GIT_EXEC_PATH=${pkgs-stable.git}/libexec/git-core PATH=${pkgs-stable.lib.makeBinPath [ pkgs-stable.git ]} ${pkgs-stable.github-desktop}/bin/github-desktop %U";
        icon = "github-desktop";
        categories = [ "Development" ];
        mimeType = [ "x-scheme-handler/x-github-client" "x-scheme-handler/x-github-desktop-auth" "x-scheme-handler/x-github-desktop-dev-auth" ];
        terminal = false;
      };
    })
  ];
}
