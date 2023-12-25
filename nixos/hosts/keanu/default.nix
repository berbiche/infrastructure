{ config, inputs, lib, pkgs, rootPath, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/minimal.nix")
    ./hardware-config.nix
  ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  configurations.mail.enable = true;
  configurations.discord-bot.jmusicbot.enable = false;

  configurations.global.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXqBarGejSu6/XzblEbsWocVCIyPxuQUCVLnMtnfrvi"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6jrY1lhogYVDj73Nzr0aXROokQ2MxsgFzqrLIfO/VffBE78GdAOs2MiYD/EYPoG5azxblujH1Nd18ohShuW6GHGsHaX8/i6lg92Ukxp8aAzdiSZSoJz6UjY9JIAquMHx4wQLuVj7TzaQ6r3UFFCzQT3zVoD1xOo1Ajww5WCUp7sYu80htEPbDoPVfjWv7PJAIibVZatV8S6mlsXoIYDoTXD2uxMe6rlWsTeYWyIocg5SBqc0dsvkOx+ga1XcKHOBSjH31osQO7FRz7jhUC69IPr++ZSfHitG25CEVyhkStF5ZZ1cuo5I0gLTgaWXreF0kjcnUtqF0KViRfeBDB9Rbhv/k816WkVLBNEsy/Bw9Ly2eDYLmdBmdp91AropRvOaMDHtjBxn3Z+4WcA+PL9rcGtwPBwFHTD3RUJcpOmo8aR58xm7usLrwIn7Ulg+kEqTll+fuhpOmyCjC6K8/uPdRconJG+eGPMpYl5Oezz0a6gX7onugw9iQkMc9cTom2RmXLrGkPEPT1ARRRxsgYqFycoyuVP2vF19HzqI1y26CTf/zKrt9q2G95NVP1Pcx1yHlpfqwnWktih+iND5INrffXiKiFWVXTrkPZY99mcM1tkQ80cDff5q4xtQLDC/yO8iVSp1mY7T+J4tpA6FrCUk2FTT5yVIf6o1d4oJPwZxr4Q=="
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "nic.berbiche@gmail.com";
  security.acme.defaults.server = "https://acme-v02.api.letsencrypt.org/directory";
}
