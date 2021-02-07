{ config, inputs, lib, pkgs, ... }:

{
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  mailserver = {
    enable = true;
  };
}
