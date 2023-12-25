{ config, rootPath, lib, pkgs, ... }:

{
  sops.secrets."cache-signing-key" = {
    format = "binary";
    mode = "0400";
    sopsFile = rootPath + "/secrets/nixos-builder-store-key.pem";
  };

  nix.settings.secret-key-files = config.sops.secrets."cache-signing-key".path;
}
