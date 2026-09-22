{ pkgs, ... }:

let
  updateInstalledJson = pkgs.writeShellApplication {
    name = "update-installed-json";
    runtimeInputs = with pkgs; [ coreutils jq nix ];
    text = ''
      flake="''${1:-/etc/nixos}"
      output="$flake/hosts/hp-laptop/system/installed.json"

      packages_json=$(
        nix eval --json "$flake#nixosConfigurations.hp-laptop.config.environment.systemPackages" \
          --apply 'packages: builtins.map (package: package.pname or package.name) packages'
      )

      jq -n --argjson packages "$packages_json" '
        {
          description: "Packages already installed system-wide (via environment.systemPackages and NixOS options like programs.*, services.*, hardware.*). Do NOT add these to apps/*.",
          packages: (($packages + [
            "dbus",
            "flatpak",
            "gnome-keyring",
            "hyprland",
            "networkmanager",
            "nh",
            "nvidia-x11",
            "pipewire",
            "podman",
            "polkit",
            "power-profiles-daemon",
            "sddm",
            "styling",
            "tailscale",
            "xwayland",
            "zsh"
          ]) | unique | sort)
        }
      ' > "$output"
    '';
  };
in
{
  environment.systemPackages = [ updateInstalledJson ];

  system.activationScripts.updateInstalledJson = {
    text = "${updateInstalledJson}/bin/update-installed-json /etc/nixos";
    deps = [ ];
  };
}
