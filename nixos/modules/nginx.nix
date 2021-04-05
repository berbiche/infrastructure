{ config, lib, pkgs, ... }:

{
  options.services.nginx.defaultServerBlock = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Defines the extraConfig block to be reused in vhosts";
  };
}
