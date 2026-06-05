{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.python-dotenv
      ];
    })
  ];
}
