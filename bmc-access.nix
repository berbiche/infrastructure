# To be executed with `nix run .#bmc -- path-to-jnlp.jnlp`
{ nixpkgs }:

let
  defaultSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  genAttrs = list: fun: builtins.foldl' (c: d: c // d) {} (map (x: { ${x} = fun x; }) list);
  eachNixpkgs = f: genAttrs defaultSystems (system: let
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  in f pkgs);
in eachNixpkgs (pkgs: let
  java = pkgs.jre8Plugin;
  javaSecurity = pkgs.writeText "bmc-java.security" ''
    # jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 128
    jdk.jar.disabledAlgorithms=
    # jdk.certpath.disabledAlgorithms=MD2, MD5, RSA keySize < 128
  '';
in {
  bmc = pkgs.writeShellScriptBin "bmc" ''
    usage () {
      cat <<EOF${"\n" + ''
        A shell script to access my old server's BMC using oraclejre8 and low
        security options.

        Usage:
          $(basename "$0") FILE

        Options:
          -h, --help      Print this help message
          -v, --verbose   Pass the 'verbose' flag to the JNLP

        Args:
          <FILE>: JNLP file to use
      ''}EOF
    }

    if [ "$#" -eq 0 ]; then
        echo "Missing <FILE> argument"
        usage
        exit 1
    fi

    TEMP=$(${pkgs.getopt}/bin/getopt -s bash -o +vh --long verbose,help -n bmc -- "$@")
    if [ $? -ne 0 ]; then
        usage
        exit 1
    fi

    eval set -- "$TEMP"
    unset TEMP

    VERBOSE=""
    while true; do
        case "$1" in
            '-h'|'--help') usage; exit 1;;
            '-v'|'--verbose') VERBOSE="-verbose"; shift;;
            '--') shift; break;;
            *) echo "$1"; usage; exit 1;;
        esac
    done
    shift $(($OPTIND - 1))

    FILE="$1"
    echo "File: $FILE"

    ${java}/bin/javaws $VERBOSE -J'-Djava.security.debug=properties' -J'-Djava.security.properties=file:${javaSecurity}' "$FILE"
  '';
})

