{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.coredns;

  innerBlockConfigType = types.oneOf [
    types.str
    (types.attrsOf types.str)
  ];
in
{
  options.services.coredns.blocks = mkOption {
    type = types.attrsOf (types.listOf innerBlockConfigType);
    default = { };
    example = literalExample ''
      {
        "." = {

        };
        "example.org" = [
           { "file" = "example.org.signed"; }
           # Using an environment variable
        ];
      }
    '';
    description = ''
      Structured configuration for Coredns blocks.
    '';
  };

  config = mkIf (cfg.enable && cfg.zones != null) {
  };
}
