{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;
in
{
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  options.configurations.mail.enable = lib.mkEnableOption "mail configuration";

  config = lib.mkIf cfg.enable {
    mailserver = {
      enable = true;
    };
  };
}
