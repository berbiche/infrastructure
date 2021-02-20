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
}
