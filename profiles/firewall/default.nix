{ config, lib, pkgs, ... }:

let
  # Copied from github.com/andir/infra/config/servers/bertha/default.nix
  # Author:
  # License: MIT
  verifiedNetFilter = text:
    let
      file = pkgs.writeText "netfilter" text;

      vmTools = pkgs.vmTools.override {
        rootModules = [
          "virtio_pci"
          "virtio_mmio"
          "virtio_blk"
          "virtio_balloon"
          "virtio_rng"
          "ext4"
          "unix"
          "9p"
          "9pnet_virtio"
          "crc32c_generic"
        ];
      };

      check = vmTools.runInLinuxVM (
        pkgs.runCommand "nft-check" {
          inherit file;
          buildInputs = [ pkgs.nftables ];
        } ''
          set -ex
          ln -s ${pkgs.iana-etc}/etc/protocol /etc/protocol
          ln -s ${pkgs.iana-etc}/etc/services /etc/services
          nft --file $file
          set +x
        '');
    in
      "#checked with ${check}\n${text}";
in
{
  options.firewall.rules = with lib; mkOption {
    type = types.lines;
    default = "";
    description = "";
  };
}
