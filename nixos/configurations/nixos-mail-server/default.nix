{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;
in
{
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  options.configurations.mail.enable = lib.mkEnableOption "mail configuration";

  config = lib.mkIf cfg.enable {
    sops.secrets.admin-pass = { };

    mailserver = {
      enable = true;
      fdqn = "mail.normie.dev";
      domains = [ "normie.dev" ];
      loginAccounts = {
        "nicolas@normie.dev" = {
          hashedPasswordFile = config.sops.secrets.admin-pass.path;
        };
      };
    };
  };
}
