{ lib, ... }:

{
  home-manager.sharedModules = [
    ({ ... }: {
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {

          format = "[](base00)$os$username\[@](bg:base00 fg:base04)$hostname\[](bg:base01 fg:base00)$directory\[](fg:base01 bg:base02)$git_branch$git_status\[](fg:base02 bg:base03)$c$rust$golang$nodejs$php$java$kotlin$haskell$python\[ ](fg:base03)$line_break$character";

          scan_timeout = 100;
          command_timeout = 1000;

          os = {
            style = "bg:base00 fg:base0F";
            disabled = false;
            symbols = {
              Windows = "󰍲";
              Ubuntu = "󰕈";
              SUSE = "";
              Raspbian = "󰐿";
              Mint = "󰣭";
              Macos = "";
              Manjaro = "";
              Linux = "󰌽";
              Gentoo = "󰣨";
              Fedora = "󰣛";
              Alpine = "";
              Amazon = "";
              Android = "";
              Arch = "󰣇";
              Artix = "󰣇";
              CentOS = "";
              Debian = "󰣚";
              Redhat = "󱄛";
              RedHatEnterprise = "󱄛";
            };
          };

          username = {
            show_always = true;
            style_user = "bg:base00 fg:base04";
            style_root = "bg:base00 fg:base04";
            format = "[$user]($style)";
          };

          hostname = {
            ssh_only = false;
            ssh_symbol = " ";
            trim_at = ".";
            format = "[$hostname$ssh_symbol ]($style)";
            style = "bg:base00 fg:base04";
          };

          directory = {
            style = "bg:base01 fg:base04";
            format = "[ $path ]($style)";
            read_only = " 󰌾 ";
            read_only_style = "bg:base01 fg:base08";
            truncation_length = 3;
            truncation_symbol = "…/";
            substitutions = {
              Documents = "󰈙 ";
              Downloads = " ";
              Music = "󰝚 ";
              Pictures = " ";
              Developer = "󰲋 ";
            };
          };

          git_branch = {
            symbol = "";
            style = "bg:base02 fg:base04";
            format = "[ $symbol $branch ]($style)";
          };

          git_status = {
            style = "bg:base02 fg:base04";
            format = "[$all_status$ahead_behind ]($style)";
          };

          nodejs = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          c = {
            symbol = " ";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          golang = {
            symbol = " ";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          php = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          java = {
            symbol = " ";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          kotlin = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          haskell = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          python = {
            symbol = "";
            style = "bg:base03 fg:base04";
            format = "[ $symbol ($version) ]($style)";
          };

          docker_context = {
            symbol = "";
            style = "bg:base04";
            format = "[[ $symbol( $context) ]]($style)";
          };

          line_break.disabled = false;

          character = {
            disabled = false;
            success_symbol = "[](bold fg:base0B)";
            error_symbol = "[](bold fg:base08)";
          };
        };
      };
    })
  ];
}
