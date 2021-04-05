{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    system = "x86_64-linux";
    pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    sops-nix = inputs.sops-nix.packages.${system};
    terraform = pkgs.terraform_0_14;

    nodesConfigurations = import ./nixos/hosts/deployments.nix {
      inherit inputs system;
      rootPath = ./nixos;
    };

  in nodesConfigurations // {

    packages = import ./scripts/bmc-access.nix { inherit nixpkgs; };

    overlays.packages = import ./nixos/pkgs;
    overlays.inputs = final: prev: { inherit inputs; };

    # FHS for the terraform-provider-b2
    # because writing a derivation is complex (it embeds a python binary generated with pyinstaller)
    defaultPackage.${system} =
      (pkgs.buildFHSUserEnv {
        name = "fhs-1";
        targetPkgs = pkgs: [
          pkgs.sops
          terraform
          pkgs.zlib
        ];
        # Only one line can be in the runScript option
        runScript = ''
          sops exec-env secrets/terraform-backend.yaml ${pkgs.writeShellScript "fhs-terraform-sops" ''
            export PS1="\e[0;32m(keanu-shell)\e[m \e[0;34m\w\e[m \e[0;31m$\e[m "
            exec bash --norc
          ''}
        '';
      }).env;

    devShell.x86_64-linux = pkgs.mkShell {
      nativeBuildInputs = [
        sops-nix.sops-pgp-hook
        # (pkgs.makeSetupHook {
        #   name = "sops-terraform-hook";
        #   substitutions.sops = "${pkgs.sops}/bin/sops";
        #   deps = [ pkgs.sops pkgs.gnupg ];
        # } (pkgs.writeShellScript "sops-terraform-hook" ''
        #   echo "Plug-in and touch the YubiKey"
        #   eval "$(@sops@ --decrypt --output-type dotenv secrets/terraform-backend.yaml)"
        # ''))
      ];

      # sopsPGPKeyDirs = [
      #   "./secrets/keys"
      # ];

      buildInputs = [
        deploy-rs.defaultPackage.${system}
        terraform
        sops-nix.ssh-to-pgp
        pkgs.sops
        pkgs.python38
        pkgs.ansible_2_9
        pkgs.pipenv
        pkgs.kubectl
        pkgs.kubetail
        pkgs.kubectx
        (pkgs.runCommandLocal "calico-3.18.1" rec {
          pname = "calico";
          version = "3.18.1";
          src = pkgs.fetchurl {
            url = "https://github.com/projectcalico/calicoctl/releases/download/v${version}/calicoctl-linux-amd64";
            hash = "sha256-KdDcZ0WMH7iVC1wVfeQQRdT1AuuAeR14WMemJSwjkME=";
          };
        } ''
          mkdir -p $out/bin
          install -Dm0755 $src $out/bin/calicoctl
        '')
      ];

      # For calico
      DATASTORE_TYPE = "kubernetes";

      shellHook = ''
        export KUBECONFIG=$PWD/kubespray/inventory/artifacts/admin.conf
      '';
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
