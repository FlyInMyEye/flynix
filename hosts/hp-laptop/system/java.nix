{ pkgs, ... }:

{
  environment.variables = {
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    AWT_TOOLKIT = "MToolkit";
  };
}
