{ pkgs, ... }:

let
  resumeOffset = pkgs.writeShellApplication {
    name = "resume-offset";
    runtimeInputs = with pkgs; [ e2fsprogs gawk ];
    text = ''
      swapfile="''${1:-/var/lib/swapfile}"

      if [ ! -f "$swapfile" ]; then
        printf 'resume-offset: swapfile not found: %s\n' "$swapfile" >&2
        exit 1
      fi

      filefrag -v "$swapfile" | awk '
        /^[[:space:]]*[0-9]+:/ {
          value = $4
          gsub(/\.\./, "", value)
          gsub(/:$/, "", value)
          print value
          found = 1
          exit
        }
        END {
          if (!found) {
            print "resume-offset: could not parse filefrag output" > "/dev/stderr"
            exit 1
          }
        }
      '
    '';
  };
in
{
  environment.systemPackages = [ resumeOffset ];
}
