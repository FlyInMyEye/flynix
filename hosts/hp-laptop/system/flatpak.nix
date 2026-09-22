{ pkgs, ... }:

{
  services.flatpak.enable = true;

  systemd.services.flatpak-config = {
    description = "Configure Flatpak remotes";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "flatpak-config" ''
        if ${pkgs.flatpak}/bin/flatpak remotes --system --columns=name | ${pkgs.gnugrep}/bin/grep -qx flathub; then
          exit 0
        fi

        if ! ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
          printf '%s\n' 'flatpak-config: could not add flathub right now; retry after network is up.' >&2
          exit 0
        fi
      '';
    };
  };
}
