{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.mail;

  autoconfigFile = pkgs.writeTextFile {
    name = "thunderbird-autoconfig";
    destination = "/config.xml";
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>

      <clientConfig version="1.1">
        <emailProvider id="${cfg.baseDomain}">
          <domain>${cfg.baseDomain}</domain>
          <displayName>${config.mailserver.fqdn} (simple-nixos-mailserver)</displayName>
          <displayShortName>${cfg.baseDomain}</displayShortName>
          <incomingServer type="imap">
            <hostname>${config.mailserver.fqdn}</hostname>
            <port>993</port>
            <socketType>SSL</socketType>
            <username>%EMAILADDRESS%</username>
            <authentication>password-cleartext</authentication>
          </incomingServer>
          <outgoingServer type="smtp">
            <hostname>${config.mailserver.fqdn}</hostname>
            <port>465</port>
            <socketType>SSL</socketType>
            <username>%EMAILADDRESS%</username>
            <authentication>password-cleartext</authentication>
          </outgoingServer>
        </emailProvider>
      </clientConfig>
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."${config.mailserver.fqdn}" = {
      locations."= /.well-known/autoconfig/mail/config-v1.1.xml" = {
        alias = "${autoconfigFile}/config.xml";
      };
    };
  };
}
