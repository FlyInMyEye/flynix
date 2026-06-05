{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      programs.firefox = {
        enable = true;
        configPath = ".mozilla/firefox";
      };
    })
  ];
}
