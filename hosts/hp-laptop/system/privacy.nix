{ config, pkgs, ... }:

let
  username = builtins.head (builtins.attrNames config.home-manager.users);
  userHome = config.home-manager.users.${username}.home.homeDirectory;
in
{
  systemd.services.clear-browser-history = {
    description = "Clear browser history on boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      ExecStart = pkgs.writeShellScript "clear-browser-history" ''
        FIREFOX_PROFILE_DIR="${userHome}/.mozilla/firefox"
        if [ -d "$FIREFOX_PROFILE_DIR" ]; then
          for profile in "$FIREFOX_PROFILE_DIR"/*.default*; do
            if [ -d "$profile" ]; then
              echo "Clearing Firefox tracking data: $profile"

              if [ -f "$profile/places.sqlite" ]; then
                ${pkgs.sqlite}/bin/sqlite3 "$profile/places.sqlite" <<EOF
DELETE FROM moz_historyvisits;
DELETE FROM moz_places WHERE visit_count = 0;
DELETE FROM moz_inputhistory;
VACUUM;
EOF
              fi

              if [ -f "$profile/places.sqlite" ]; then
                ${pkgs.sqlite}/bin/sqlite3 "$profile/places.sqlite" "DELETE FROM moz_annos WHERE anno_attribute_id IN (SELECT id FROM moz_anno_attributes WHERE name LIKE '%download%');"
              fi

              rm -rf "$profile/cache2" || true
              rm -rf "$profile/thumbnails" || true
              rm -rf "$profile/OfflineCache" || true
              rm -rf "$profile/startupCache" || true
            fi
          done
        fi

        LIBREWOLF_PROFILE_DIR="${userHome}/.librewolf"
        if [ -d "$LIBREWOLF_PROFILE_DIR" ]; then
          for profile in "$LIBREWOLF_PROFILE_DIR"/*.default*; do
            if [ -d "$profile" ]; then
              echo "Clearing LibreWolf tracking data: $profile"

              if [ -f "$profile/places.sqlite" ]; then
                ${pkgs.sqlite}/bin/sqlite3 "$profile/places.sqlite" <<EOF
DELETE FROM moz_historyvisits;
DELETE FROM moz_places WHERE visit_count = 0;
DELETE FROM moz_inputhistory;
VACUUM;
EOF
              fi

              rm -rf "$profile/cache2" || true
              rm -rf "$profile/thumbnails" || true
              rm -rf "$profile/OfflineCache" || true
              rm -rf "$profile/startupCache" || true
            fi
          done
        fi

        echo "Browser tracking data cleared on boot (cookies, autocomplete & tabs preserved)"
      '';
    };
  };

  systemd.services.clear-terminal-history = {
    description = "Clear terminal history on boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      ExecStart = pkgs.writeShellScript "clear-terminal-history" ''
        rm -f ${userHome}/.bash_history || true
        rm -f ${userHome}/.zsh_history || true
        rm -f ${userHome}/.local/share/fish/fish_history || true
        rm -f ${userHome}/.python_history || true
        rm -f ${userHome}/.node_repl_history || true
        rm -f ${userHome}/.mysql_history || true
        rm -f ${userHome}/.psql_history || true
        rm -f ${userHome}/.rediscli_history || true
        rm -f ${userHome}/.lesshst || true
        rm -f ${userHome}/.wget-hsts || true

        echo "Terminal history cleared on boot (zoxide cache preserved)"
      '';
    };
  };
}
