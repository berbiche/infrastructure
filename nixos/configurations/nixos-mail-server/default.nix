{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;
in
{
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  options.configurations.mail.enable = lib.mkEnableOption "mail configuration";

  config = lib.mkIf cfg.enable {
    sops.secrets.admin-pass = { };
    # sops.secrets.roundcube-db-pass = { };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    mailserver = {
      enable = true;
      fqdn = "mail.normie.dev";
      domains = [ "normie.dev" ];
      certificateDomains = [ "normie.dev" "mail.normie.dev" ];

      enableImap = false;
      enableImapSsl = true;
      enableSubmission = false;
      enableSubmissionSsl = true;

      loginAccounts = {
        "nicolas@normie.dev" = {
          hashedPasswordFile = config.sops.secrets.admin-pass.path;
          catchAll = [ "normie.dev" ];
        };
      };
      extraVirtualAliases = {
        "postmaster@normie.dev" = "nicolas@normie.dev";
        "abuse@normie.dev" = "nicolas@normie.dev";
        "nic.berbiche+era@normie.dev" = "nicolas@normie.dev";
        "nic.berbiche@normie.dev" = "nicolas@normie.dev";
      };
      forwards = { "nicolas@normie.dev" = "nic.berbiche@gmail.com"; };


      # Store mails in /var/vmail/example.com/user/folder/subfolder
      useFsLayout = true;
      hierarchySeparator = "/";

      dkimKeyBits = 2048;

      # Monit monitoring
      monitoring.enable = true;
      monitoring.alertAddress = "nic.berbiche@gmail.com";

      # Uses Let's Encrypt HTTP challenge to get a certificate
      certificateScheme = 3;

      fullTextSearch.indexAttachments = false;
    };

    services.roundcube = {
      enable = true;
      hostName = "${config.mailserver.fqdn}";
      package = pkgs.roundcube.withPlugins (ps: [ ps.persistent_login ]);
      plugins = [ "persistent_login" ];
      dicts =
        let ps = pkgs.aspellDicts; in
        [ ps.en ps.fr ];

      extraConfig = ''
        $config['default_port'] = 993;
        $config['default_host'] = 'ssl://${config.mailserver.fqdn}';

        $config['imap_auth_type'] = 'LOGIN';

        $config['smtp_port'] = 587;
        $config['smtp_server'] = 'tls://${config.mailserver.fqdn}';
        $config['smtp_user'] = '%u';
        $config['smtp_pass'] = '%p';
      '';
    };
  };
}
