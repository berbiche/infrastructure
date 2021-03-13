{ config, lib, pkgs, modulesPath, rootPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  networking.hostName = "mouse";
  networking.domain = "tq.rs";

  configurations.qemu-node = {
    enable = true;
    VLAN-1-ipv4CIDR = "192.168.0.6/24";
    VLAN-1-gateway = "192.168.0.1";
    VLAN-42-ipv4CIDR = "192.168.42.6/24";
  };
}
