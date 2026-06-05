{ ... }:

{
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.libreoffice-fresh ];

      home.file.".config/libreoffice/4/user/registrymodifications.xcu".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/Writer"><prop oor:name="Mode" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
          <item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/Calc"><prop oor:name="Mode" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
          <item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/Impress"><prop oor:name="Mode" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
          <item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="SymbolStyle" oor:op="fuse"><value>colibre</value></prop></item>
        </oor:items>
      '';
    })
  ];
}
