{ ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion = {
          enable = true;
          highlight = "fg=#4C566A";
        };
        shellAliases = {
          list-nixos-generations = "nixos-rebuild list-generations";
          flake-check = "nix flake check";
          size = "du -ah --max-depth=1 | sort -h";
          ip-show = "curl ifconfig.me";
          mostra-connessioni = "nmcli device wifi list";
          hotspot-telefono = "nmcli device wifi connect Light3r";
          nrs = "sudo nixos-rebuild switch --flake /etc/nixos";
          nrt = "sudo nixos-rebuild test --flake /etc/nixos";
          nrb = "sudo nixos-rebuild boot --flake /etc/nixos";
          hms = "home-manager switch --flake /etc/nixos";
          fu = "cd /etc/nixos && nix flake update";
          gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
          hypr-reload = "hyprctl reload";
          gpu-status = "nvidia-smi";
          steam-fix = "killall steam && steam";
          ports = "ss -tuln";
          ll = "eza -alF --icons";
          la = "eza -A --icons";
          l = "eza -F --icons";
          ls = "eza --icons";
          grep = "rg";
          df = "df -h";
          free = "free -h";
          ps = "ps auxf";
          mkdir = "mkdir -pv";
          cat = "bat";
          tree = "eza --tree --icons";
          cd = "z";
        };
        initContent = ''
          export XCURSOR_THEME="$HOME/.icons/macOS"
          export XCURSOR_SIZE=24
          export PATH="$HOME/.local/bin:$PATH"
          export PATH="$HOME/.cargo/bin:$PATH"
          export PATH="/Nixos/scripts:$PATH"
          export PATH="/Nixos/scripts/nixos:$PATH"
          export PATH="/Nixos/scripts/hypr:$PATH"

          alpine() {
            if [ "$1" = "-t" ]; then
              podman run --rm -it --hostname alpine alpine:latest sh
              return
            fi

            if [ -n "$1" ]; then
              printf 'usage: alpine [-t]\n' >&2
              return 1
            fi

            if ! podman container exists alpine; then
              podman create -it --name alpine --hostname alpine alpine:latest sh >/dev/null
            fi

            podman start -ai alpine
          }

          if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM" != "linux" ]; then
            tmux new-session -A -s main
          fi
        '';
      };
    })
  ];
}
