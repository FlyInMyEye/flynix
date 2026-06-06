{ pkgs, ... }:

{
  plymouth-deadlight = pkgs.stdenv.mkDerivation {
    name = "plymouth-deadlight";
    src = pkgs.fetchFromGitHub {
      owner = "MrVivekRajan";
      repo = "Plymouth-Themes";
      rev = "main";
      sha256 = "sha256-3RaDpk+BGI+XNXpw8cyUrr+X00OhYuAH03VJ56TBjns=";
    };

    buildInputs = [ pkgs.plymouth ];

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/deadlight
      cp -r Deadlight/* $out/share/plymouth/themes/deadlight/

      # Fix the .plymouth file name to lowercase for consistency
      if [ -f $out/share/plymouth/themes/deadlight/Deadlight.plymouth ]; then
        mv $out/share/plymouth/themes/deadlight/Deadlight.plymouth $out/share/plymouth/themes/deadlight/deadlight.plymouth
      fi

      # Update paths to use the Nix store output path
      sed -i "s|ImageDir=.*|ImageDir=$out/share/plymouth/themes/deadlight|g" \
        $out/share/plymouth/themes/deadlight/deadlight.plymouth
      sed -i "s|ScriptFile=.*|ScriptFile=$out/share/plymouth/themes/deadlight/Deadlight.script|g" \
        $out/share/plymouth/themes/deadlight/deadlight.plymouth

      # Ensure proper permissions
      chmod 644 $out/share/plymouth/themes/deadlight/* || true
    '';

    meta = {
      description = "Deadlight Plymouth boot splash theme";
      homepage = "https://github.com/MrVivekRajan/Plymouth-Themes";
      license = pkgs.lib.licenses.gpl3;
    };
  };
}
