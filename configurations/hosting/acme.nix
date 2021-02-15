{ config, rootPath, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  domain = config.networking.domain;
  dnsProvider = "cloudflare";
  email = "nic.berbiche" + "@" + "gmail.com";

  sslDirectoryFor = x: config.security.acme.certs."${x}".directory;

  credentialsFile = config.sops.secrets."acme-cloudflare".path;
  defaultCert = { inherit dnsProvider credentialsFile; };
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets."acme-cloudflare" = {
      format = "binary";
      owner = "acme";
      group = "acme";
      sopsFile = rootPath + "/secrets/acme.txt";
    };

    security.acme.acceptTerms = true;
    security.acme.email = email;
    # Staging environment for test purposes
    security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

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
