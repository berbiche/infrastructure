{ config, lib, pkgs, ... }:

let
  mtaDomain = "mta-sts.normie.dev";

  mtaStsFile = pkgs.writeTextFile {
    name = "mta-sts";
    destination = "/mta-sts.txt";
    text = ''
      version: STSv1
      mode: testing
      mx: ${toString config.mailserver.fqdn}
      max_age: 86400
    '';
  };

  cfg = config.configurations.mail;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ mtaStsFile ];

    # mailserver.certificateDomains = [ "${mtaDomain}" ];

    services.nginx.virtualHosts."${mtaDomain}" = {
      serverName = "${mtaDomain}";
      enableACME = true;
      forceSSL = true;

      ## No need for autoindex since I haven't set a root directory
      # locations."= /.well-known/" = {
      #   extraConfig = ''
      #     autoindex on;
      #     autoindex_format html;
      #   '';
      # };

      locations."= /.well-known/mta-sts.txt" = {
        alias = "${mtaStsFile}/mta-sts.txt";
        extraConfig = ''
          sendfile   on;
          tcp_nopush on;
        '';
      };

      locations."/dev/null" = {
        extraConfig = ''
          if ($request_method = POST) {
            return 410;
          }
        '';
      };

      locations."/" = {
        return = "404";
      };
    };
  };
}
