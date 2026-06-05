# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs, inputs }:
let
  wallpaper = ../wallpapers/this-wallpaper-is-not-available.png;
in {
  sddm-eucalyptus-drop = pkgs.stdenv.mkDerivation {
    name = "sddm-eucalyptus-drop";
    src = inputs.sddm-eucalyptus-drop;

    buildPhase = ''
      cat > theme.conf << 'EOF'
[General]

Background=Backgrounds/custom-wallpaper.png
DimBackgroundImage=0.0
ScaleImageCropped=true
ScreenWidth=1920
ScreenHeight=1080

FullBlur=true
PartialBlur=false
BlurRadius=25

HaveFormBackground=false
FormPosition=center
BackgroundImageHAlignment=center
BackgroundImageVAlignment=center

MainColour=#999FAB
AccentColour=#343A46
BackgroundColour=#BBC1CD
OverrideLoginButtonTextColour=
InterfaceShadowSize=6
InterfaceShadowOpacity=0.6
RoundCorners=20
ScreenPadding=0

Font=Noto Sans
FontSize=

ForceRightToLeft=false
ForceLastUser=true
ForcePasswordFocus=true
ForceHideCompletePassword=true
ForceHideVirtualKeyboardButton=false
ForceHideSystemButtons=false
AllowEmptyPassword=false
AllowBadUsernames=false

Locale=
HourFormat=HH:mm
DateFormat=dddd d MMMM

HeaderText=
TranslatePlaceholderUsername=
TranslatePlaceholderPassword=
TranslateShowPassword=
TranslateLogin=
TranslateLoginFailedWarning=
TranslateCapslockWarning=
TranslateSession=
TranslateSuspend=
TranslateHibernate=
TranslateReboot=
TranslateShutdown=
TranslateVirtualKeyboardButton=
EOF
    '';

    installPhase = ''
      mkdir -p $out/share/sddm/themes/eucalyptus-drop
      cp -r * $out/share/sddm/themes/eucalyptus-drop/
      cp ${wallpaper} $out/share/sddm/themes/eucalyptus-drop/Backgrounds/custom-wallpaper.png
    '';
  };

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
