{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;
in
{
  config = lib.mkIf cfg.enable {
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

    services.nginx.enable = true;

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
