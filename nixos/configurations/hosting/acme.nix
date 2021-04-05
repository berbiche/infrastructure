{ config, rootPath, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  domain = config.networking.domain;

  sslDirectoryFor = x: config.security.acme.certs."${x}".directory;

  defaultCert = {
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets."acme-cloudflare".path;
  };
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets."acme-cloudflare" = {
      format = "binary";
      owner = "acme";
      group = "acme";
      sopsFile = rootPath + "/secrets/acme.txt";
    };

    services.nginx.virtualHosts."${domain}" = {
      useACMEHost = domain;
      sslCertificate = "${sslDirectoryFor domain}/fullchain.pem";
      forceSSL = true;
    };

    security.acme.certs = {
      "${domain}" = defaultCert // {
        extraDomainNames = [ "www.${domain}" ];
      };
      "cloud.${domain}" = defaultCert // {
        extraDomainNames = [ "*.cloud.${domain}" ];
      };
      "mail.${domain}" = defaultCert;
    };
  };
}
