{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    })
  ];
}
