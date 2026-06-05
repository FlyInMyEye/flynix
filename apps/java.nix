{ ... }:

{
  home-manager.sharedModules = [
    ({ config, pkgs, ... }:
      let
        jdk8 = pkgs.jdk8;
        jdk17 = pkgs.jdk17;
        jdk21 = pkgs.jdk21;
      in {
        home.packages = with pkgs; [
          maven
          gradle
          jdt-language-server
          (writeShellScriptBin "java" ''
            exec ${jdk21}/bin/java "$@"
          '')
        ];

        home.file = {
          ".jdks/jdk8".source = jdk8;
          ".jdks/jdk17".source = jdk17;
          ".jdks/jdk21".source = jdk21;

          ".gradle/gradle.properties".text = ''
            org.gradle.java.installations.auto-detect=false
            org.gradle.java.installations.paths=${config.home.homeDirectory}/.jdks/jdk8,${config.home.homeDirectory}/.jdks/jdk17,${config.home.homeDirectory}/.jdks/jdk21
          '';
        };

        home.sessionVariables = {
          JAVA8_HOME = "${config.home.homeDirectory}/.jdks/jdk8";
          JAVA17_HOME = "${config.home.homeDirectory}/.jdks/jdk17";
          JAVA21_HOME = "${config.home.homeDirectory}/.jdks/jdk21";
          JAVA_HOME = "${config.home.homeDirectory}/.jdks/jdk17";
        };
      })
  ];
}
