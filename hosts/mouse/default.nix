{ config, lib, pkgs, modulesPath, rootPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  networking.hostName = "mouse";
  networking.domain = "node.tq.rs";

  configurations."tq.rs".enable = true;

  configurations.hosting = {
    enable = true;
    traefik.enable = true;
    traefik.domain = "tq.rs";
    traefik.enableACME = false;
  };

  configurations.qemu-node = {
    enable = true;
    dnsServers = [ "127.0.0.1" "::1" "8.8.8.8" "8.8.4.4" ];
    VLAN-1-ipv4CIDR = "192.168.0.6/24";
    VLAN-1-gateway = "192.168.0.1";
    VLAN-42-ipv4CIDR = "192.168.42.6/24";
  };

  # We use coredns
  services.dnsmasq.enable = false;
}
