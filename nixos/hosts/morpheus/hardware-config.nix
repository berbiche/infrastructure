{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.blacklistedKernelModules = [ "iwlwifi" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7cfdfce0-a43c-44eb-8b56-99fe291f3290";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/4247-75AB";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/30f9bae2-e5eb-4229-ba5a-e676bd6138b0"; }
    ];

  networking.useDHCP = false;

  networking.useNetworkd = true;
  systemd.network.enable = true;
  services.resolved.enable = true;

  systemd.network.links."00-ens1" = {
    linkConfig.Name = "ens1";
    matchConfig.MACAddress = "94:c6:91:a9:1e:f3";
    # :))) https://bugzilla.redhat.com/show_bug.cgi?id=1741678
    linkConfig.NamePolicy = "keep";
    matchConfig.Type = "!vlan bridge";
  };
  systemd.network.netdevs."ens1.42" = {
    netdevConfig.Kind = "vlan";
    netdevConfig.Name = "ens1.42";
    vlanConfig.Id = 42;
  };
  systemd.network.networks."ens1" = {
    name = "ens1";
    networkConfig = {
      DHCP = "no";
      VLAN = [ "ens1.42" ];
      LinkLocalAddressing = "no";
      LLDP = "no";
      EmitLLDP = "no";
      IPv6AcceptRA = "no";
      IPv6SendRA = "no";
    };
  };
  systemd.network.networks."ens1.42" = {
    linkConfig.RequiredForOnline = true;
    matchConfig.Name = "ens1.42";
    matchConfig.Type = "vlan";
    networkConfig = {
      DHCP = "no";
      Address = "10.97.42.9/24";
      Gateway = "10.97.42.1";
      DNS = "10.97.42.1";
      NTP = [ "10.97.42.1" ];

      ConfigureWithoutCarrier = "yes";
      DNSSEC = false;
      LLDP = "routers-only";
      EmitLLDP = "nearest-bridge";
      DNSDefaultRoute = true;
    };
  };

  services.lldpd.enable = true;
}
