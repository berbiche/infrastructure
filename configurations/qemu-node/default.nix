{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.configurations.qemu-node;
in
{
  options.configurations.qemu-node = {
    enable = lib.mkEnableOption "qemu-node configuration profile";
    VLAN-1-ipv4CIDR = lib.mkOption {
      type = lib.types.str;
      example = "192.168.0.6/24";
      description = "VLAN 1 IPv4 address with CIDR";
    };
    VLAN-42-ipv4CIDR = lib.mkOption {
      type = lib.types.str;
      example = "192.168.42.6/24";
      description = "VLAN 1 IPv4 address with CIDR";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    swapDevices = [ ];

    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "/dev/sda";

    networking.hostName = lib.mkDefault "nixos";
    networking.firewall.enable = true;
    networking.useDHCP = false;
    networking.useNetworkd = true;
    systemd.network.enable = true;
    systemd.network.networks.ens18 = {
      name = "ens18";
      DHCP = "ipv6";
      addresses = [{
        addressConfig.Address = cfg.VLAN-1-ipv4CIDR;
      }];
    };
    systemd.network.networks.ens19 = {
      name = "ens19";
      DHCP = "ipv6";
      addresses = [{
        addressConfig.Address = cfg.VLAN-42-ipv4CIDR;
      }];
    };

    time.timeZone = lib.mkDefault "America/Montreal";
    i18n.defaultLocale = "en_US.UTF-8";
    environment.noXlibs = lib.mkDefault true;

    users.users.root = {
      initialPassword = "root";
    };

    programs.mtr.enable = true;
    environment.systemPackages = with pkgs; [
      iotop iperf tcpdump htop netcat-gnu
    ];

    services.openssh.enable = true;
    services.openssh.permitRootLogin = false;
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
