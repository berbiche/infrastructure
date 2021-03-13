{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.configurations.qemu-node;
in
{
  options.configurations.qemu-node = {
    enable = lib.mkEnableOption "qemu-node configuration profile";
    dnsServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "8.8.8.8" "1.1.1.1" "8.8.4.4" "1.0.0.1" ];
      description = "A list of dns servers to use";
    };
    VLAN-1-ipv4CIDR = lib.mkOption {
      type = lib.types.str;
      example = "192.168.0.6/24";
      description = "VLAN 1 IPv4 address with CIDR";
    };
    VLAN-1-gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.0.1";
      description = "VLAN 1 IPv4 address";
    };
    VLAN-42-ipv4CIDR = lib.mkOption {
      type = lib.types.str;
      example = "192.168.42.6/24";
      description = "VLAN 1 IPv4 address with CIDR";
    };
    VLAN-42-gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.42.1";
      description = "VLAN 42 IPv4 address";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = let
        a = cfg.VLAN-1-gateway != null;
        b = cfg.VLAN-42-gateway != null;
      in (a && !b) || (!a && b);
      message = "Only one gateway may be set, not both or none.";
    }];

    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    boot.growPartition = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    swapDevices = [ ];

    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "/dev/sda";

    services.dnsmasq.enable = true;
    services.dnsmasq.servers = cfg.dnsServers;
    services.resolved.enable = false;

    networking.hostName = lib.mkDefault "nixos";
    networking.firewall.enable = true;
    networking.useDHCP = false;
    networking.useNetworkd = true;
    systemd.network.enable = true;
    systemd.network.networks.ens18 = {
      name = "ens18";
      DHCP = "no";
      addresses = [{
        addressConfig.Address = cfg.VLAN-1-ipv4CIDR;
      }];
      routes = lib.mkIf (cfg.VLAN-1-gateway != null) [{
        routeConfig.Gateway = cfg.VLAN-1-gateway;
      }];
    };
    systemd.network.networks.ens19 = {
      name = "ens19";
      DHCP = "no";
      addresses = [{
        addressConfig.Address = cfg.VLAN-42-ipv4CIDR;
      }];
      routes = lib.mkIf (cfg.VLAN-42-gateway != null) [{
        routeConfig.Gateway = cfg.VLAN-42-gateway;
      }];
    };

    time.timeZone = lib.mkDefault "America/Montreal";

    users.users.root.initialPassword = "root";

    programs.mtr.enable = true;
    environment.systemPackages = with pkgs; [
      iotop iperf tcpdump htop netcat-gnu
    ];

    services.openssh.enable = true;
    services.openssh.permitRootLogin = "prohibit-password";
    services.openssh.allowSFTP = true;

    services.qemuGuest.enable = true;

    nix.gc.automatic = true;
    systemd.timers.nix-gc = {
      timerConfig = {
        RandomizeDelaySec = "2 hours";
        Persistent = true;
      };
    };
  };
}
