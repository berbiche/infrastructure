{ config, inputs, lib, pkgs, rootPath, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
  ];

  configurations.mail.enable = true;
  configurations.discord-bot.jmusicbot.enable = true;

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  boot.cleanTmpDir = true;

  boot.loader.grub.device = "/dev/sda";
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

  networking.hostName = "keanu";
  networking.domain = "normie.dev";

  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "213.186.33.99" "8.8.8.8" ];
    timeServers = [
      "ntp.ovh.net"
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
    defaultGateway = "51.222.12.1";
    defaultGateway6 = "2607:5300:205:200::1";
    dhcpcd.enable = false;
    resolvconf.dnsExtensionMechanism = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "51.222.15.167"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "fe80::f816:3eff:feb6:863d"; prefixLength = 64; }
          { address = "2607:5300:205:200::404"; prefixLength = 128; }
        ];
        ipv4.routes = [ { address = "51.222.12.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2607:5300:205:200::1"; prefixLength = 128; } ];
      };

    };
  };
  # Rename device to eth0
  services.udev.extraRules = ''
    ATTR{address}=="fa:16:3e:b6:86:3d", NAME="eth0"
  '';

  # Kres is being setup by nixos-simple-mailserver
  # services.dnsmasq.enable = true;
}
