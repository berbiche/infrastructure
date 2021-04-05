{ config, lib, ... }:

with lib;

{
  options.configurations.global = {
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      # default = [
      #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
      #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
      # ];
      defaultText = literalExample ''
        [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
        ]
      '';
      description = "A list of authorized SSH keys.";
    };

    #
  };

  config = {
    configurations.global.authorizedKeys = lib.mkDefault [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
    ];
  };
}
