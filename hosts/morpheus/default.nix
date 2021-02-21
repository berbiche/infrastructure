{ config, lib, pkgs, modulesPath, ... }:

{
  configurations.plex.enable = true;
  configurations.hosting.enable = true;

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ata_piix" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "morpheus";
  networking.domain = "tq.rs";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/e3a4985e-7e54-44e2-af3e-d5ff85ea1b89";
      fsType = "ext4";
    };

  swapDevices = [ ];

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Links: LAN & WAN (rename interface)
  systemd.network.links = lib.mapAttrs (n: v: {
    matchConfig.MACAddress = v.mac;
    linkConfig.Name = v.name;
    linkConfig.Description = v.description;
  }) {
    "10-lan" = {
      name = "lan";
      mac = "c8:0a:a9:04:3b:5e";
      description = "Local network";
    };
    "10-wan" = {
      name = "wan";
      mac = "c8:0a:a9:04:3b:5f";
      description = "Internet network";
    };
  };
  # VLANS : 1, 42
  systemd.network.netdevs = lib.mapAttrs (n: v: {
    netdevConfig = removeAttrs [ "vlan" ] v;
    vlanConfig = map (x: { Id = x; }) v.vlan;
  }) {
    "10-lan" = {
      Name = "lan.1";
      Kind = "vlan";
      vlan = [ "1" ];
    };
    "10-wan" = {
      Name = "wan.42";
      Kind = "vlan";
      vlan = [ "42" ];
    };
  };
  # Networks: LAN (PVID 1), WAN (PVID 42)
  systemd.network.networks = {
    # Temporarily make it join both VLANs
    "bridged-wan" = {
      matchConfig.Name = "wan";
      vlan = [ "lan.1" "wan.42" ];
      # networkConfig = {
      #   DHCP = "yes";
      # };
      # Not necessary according to the networkd docs
      # See ARP under [LINK] section
      linkConfig.ARP = "no";
    };
    "10-wan" = {
      matchConfig.Name = "wan.42";
      networkConfig = {
        Description = "Incoming Internet network (WAN)";
        LinkLocalAddressing = "ipv6";
        IPv6LinkLocalAddressGenerationMode = "eui64";
      };
      vlan = [ "lan.1" # "server.41"
               "wan.42" ];
      address = [ "192.168.100.11" ];
    };
    "10-lan" = {
      matchConfig.Name = "lan.1";
      networkConfig = {
        Description = "";
      };
    };
  };
}
