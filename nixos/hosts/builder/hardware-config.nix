{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
      (modulesPath + "/profiles/minimal.nix")
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "ahci" "virtio_pci" "xhci_pci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  #boot.kernelParams = [ "console=ttyS0,115200" ];

  boot.growPartition = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/dfe95062-21c8-4147-9699-9ece32ac34e0";
      fsType = "ext4";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/c3f97542-2ad7-409d-a994-0206e20a2fc5";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0677-071C";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = false;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    auto-optimise-store = false;
  };

  services.qemuGuest.enable = true;

  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.enable = true;
  services.resolved.enable = true;
  systemd.network.links."10-vid42" = {
    linkConfig.Name = "ens1";
    matchConfig.MACAddress = "56:6f:d5:f3:00:12";
  };
  systemd.network.networks."30-vid42" = {
    name = "ens1";
    DHCP = "no";
    address = [ "10.97.42.8/24" ];
    gateway = [ "10.97.42.1" ];
    dns = [ "10.97.42.1" ];
    ntp = [ "10.97.42.1" ];
    vlan = [ "42" ];
  };
}
