{ config, inputs, lib, pkgs, rootPath, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
  ];

  system.stateVersion = "22.11";

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  configurations.mail.enable = true;
  configurations.discord-bot.jmusicbot.enable = true;

  configurations.global.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXqBarGejSu6/XzblEbsWocVCIyPxuQUCVLnMtnfrvi"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6jrY1lhogYVDj73Nzr0aXROokQ2MxsgFzqrLIfO/VffBE78GdAOs2MiYD/EYPoG5azxblujH1Nd18ohShuW6GHGsHaX8/i6lg92Ukxp8aAzdiSZSoJz6UjY9JIAquMHx4wQLuVj7TzaQ6r3UFFCzQT3zVoD1xOo1Ajww5WCUp7sYu80htEPbDoPVfjWv7PJAIibVZatV8S6mlsXoIYDoTXD2uxMe6rlWsTeYWyIocg5SBqc0dsvkOx+ga1XcKHOBSjH31osQO7FRz7jhUC69IPr++ZSfHitG25CEVyhkStF5ZZ1cuo5I0gLTgaWXreF0kjcnUtqF0KViRfeBDB9Rbhv/k816WkVLBNEsy/Bw9Ly2eDYLmdBmdp91AropRvOaMDHtjBxn3Z+4WcA+PL9rcGtwPBwFHTD3RUJcpOmo8aR58xm7usLrwIn7Ulg+kEqTll+fuhpOmyCjC6K8/uPdRconJG+eGPMpYl5Oezz0a6gX7onugw9iQkMc9cTom2RmXLrGkPEPT1ARRRxsgYqFycoyuVP2vF19HzqI1y26CTf/zKrt9q2G95NVP1Pcx1yHlpfqwnWktih+iND5INrffXiKiFWVXTrkPZY99mcM1tkQ80cDff5q4xtQLDC/yO8iVSp1mY7T+J4tpA6FrCUk2FTT5yVIf6o1d4oJPwZxr4Q=="
  ];

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
