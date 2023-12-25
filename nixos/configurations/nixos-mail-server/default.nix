{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModules.default
    ./roundcube.nix
    ./mta-sts.nix
    ./discovery.nix
  ];

  options.configurations.mail.enable = lib.mkEnableOption "mail configuration";
  options.configurations.mail.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "base domain to use for the email setup";
    default = "normie.dev";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.admin-pass = { };
    # sops.secrets.roundcube-db-pass = { };


    services.monit = {
      config = lib.mkBefore ''
        set mail-format {
          from: monit@${cfg.baseDomain}
        }
      '';
    };

    mailserver = {
      enable = true;
      fqdn = "mail.${cfg.baseDomain}";
      domains = [ cfg.baseDomain ];
      certificateDomains = [ cfg.baseDomain "mail.${cfg.baseDomain}" ];

      enableImap = false;
      enableImapSsl = true;
      enableSubmission = false;
      enableSubmissionSsl = true;

      loginAccounts = {
        "nicolas@normie.dev" = {
          hashedPasswordFile = config.sops.secrets.admin-pass.path;
          catchAll = [ "normie.dev" ];
          quota = "10G";
        };
      };
      extraVirtualAliases = {
        "postmaster@${cfg.baseDomain}" = "nicolas@${cfg.baseDomain}";
        "abuse@${cfg.baseDomain}" = "nicolas@${cfg.baseDomain}";
        "nic.berbiche+era@${cfg.baseDomain}" = "nicolas@${cfg.baseDomain}";
        "nic.berbiche@${cfg.baseDomain}" = "nicolas@${cfg.baseDomain}";
      };
      #forwards = { "nicolas@${cfg.baseDomain}" = "nic.berbiche@gmail.com"; };


      # Store mails in /var/vmail/example.com/user/folder/subfolder
      useFsLayout = true;
      hierarchySeparator = "/";

      dkimKeyBits = 2048;

      # Monit monitoring
      monitoring.enable = true;
      monitoring.alertAddress = "nic.berbiche@gmail.com";

      # Uses Let's Encrypt HTTP challenge to get a certificate
      certificateScheme = "acme-nginx";

      fullTextSearch.indexAttachments = false;
    };
  };
}
