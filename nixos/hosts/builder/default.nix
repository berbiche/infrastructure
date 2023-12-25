{ config, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-config.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  configurations.global.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXqBarGejSu6/XzblEbsWocVCIyPxuQUCVLnMtnfrvi"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8wdxSb9Iy3l4vXwdEmQeKxurVosXOUdcUgpae5x4Jm"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6jrY1lhogYVDj73Nzr0aXROokQ2MxsgFzqrLIfO/VffBE78GdAOs2MiYD/EYPoG5azxblujH1Nd18ohShuW6GHGsHaX8/i6lg92Ukxp8aAzdiSZSoJz6UjY9JIAquMHx4wQLuVj7TzaQ6r3UFFCzQT3zVoD1xOo1Ajww5WCUp7sYu80htEPbDoPVfjWv7PJAIibVZatV8S6mlsXoIYDoTXD2uxMe6rlWsTeYWyIocg5SBqc0dsvkOx+ga1XcKHOBSjH31osQO7FRz7jhUC69IPr++ZSfHitG25CEVyhkStF5ZZ1cuo5I0gLTgaWXreF0kjcnUtqF0KViRfeBDB9Rbhv/k816WkVLBNEsy/Bw9Ly2eDYLmdBmdp91AropRvOaMDHtjBxn3Z+4WcA+PL9rcGtwPBwFHTD3RUJcpOmo8aR58xm7usLrwIn7Ulg+kEqTll+fuhpOmyCjC6K8/uPdRconJG+eGPMpYl5Oezz0a6gX7onugw9iQkMc9cTom2RmXLrGkPEPT1ARRRxsgYqFycoyuVP2vF19HzqI1y26CTf/zKrt9q2G95NVP1Pcx1yHlpfqwnWktih+iND5INrffXiKiFWVXTrkPZY99mcM1tkQ80cDff5q4xtQLDC/yO8iVSp1mY7T+J4tpA6FrCUk2FTT5yVIf6o1d4oJPwZxr4Q=="
  ];

  users.groups.nicolas = { };
  users.users.nicolas = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    group = config.users.groups.nicolas.name;
    initialPassword = "nicolas";
    openssh.authorizedKeys.keys = config.configurations.global.authorizedKeys;
  };

  services.openssh.hostKeys = [
    # {
    #   bits = 4096;
    #   path = "/etc/ssh/ssh_host_rsa_key";
    #   type = "rsa";
    # }
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
}
