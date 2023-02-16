# FHS for the terraform-provider-b2
# because writing a derivation is complex (it embeds a python binary generated with pyinstaller)
{ pkgs, terraform, ... }:

let
  fhs = pkgs.buildFHSUserEnv {
    name = "terraform-keanu-fhs";
    targetPkgs = pkgs: [
      terraform
      pkgs.gnupg
      pkgs.sops
      pkgs.zlib
    ];
    # Only one line can be in the runScript option
    runScript = pkgs.writeShellScript "fhs-terraform-run-script" ''
      echo >&2 "This file must be executed from the root of the project"
      echo "You may need to allow GPG decryption of the secrets"
      echo "Please input your password if required"
      sops exec-env secrets/terraform-backend.yaml ${pkgs.writeShellScript "fhs-terraform-sops" ''
        : # export nix-shell name
        export name="terraform"
        exec zsh
      ''}
    '';
  };
in
  fhs // {
    meta.mainProgram = terraformFHS.name;
  }
