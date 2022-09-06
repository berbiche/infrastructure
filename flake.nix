{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-21.11";
  inputs.simple-nixos-mailserver.inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-21_05.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-21_11.url = "github:nixos/nixpkgs/nixos-21.11";
  };

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

    nodesConfigurations = import ./nixos/hosts/deployments.nix {
      inherit inputs;
      rootPath = ./nixos;
    };
  in {
    overlays.packages = import ./nixos/pkgs;
    overlays.inputs = final: prev: { inherit inputs; };

    inherit (nodesConfigurations) deploy;

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  }
  // inputs.flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      overlays = builtins.attrValues self.overlays;
    };
    sops-nix = inputs.sops-nix.packages.${system};
    terraform = pkgs.terraform_1;

    # FHS for the terraform-provider-b2
    # because writing a derivation is complex (it embeds a python binary generated with pyinstaller)
    terraformFHS = pkgs.buildFHSUserEnv {
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
    } // {
      meta.mainProgram = terraformFHS.name;
    };

  in {
    packages = {
      # nix shell .#openshift-install
      openshift-install = let
        url-and-hash = rec {
          "x86_64-linux" = {
            url = "https://github.com/openshift/okd/releases/download/4.9.0-0.okd-2022-01-14-230113/openshift-install-linux-4.9.0-0.okd-2022-01-14-230113.tar.gz";
            hash = "sha256-I1tj/cO3tXd3G1Lwii+VuFVmjQZTlzn8Q34b/YiJ+Ao=";
          };
          "x86_64-darwin" = {
            url = "https://github.com/openshift/okd/releases/download/4.9.0-0.okd-2022-01-14-230113/openshift-install-mac-4.9.0-0.okd-2022-01-14-230113.tar.gz";
            sha256 = "sha256-gJ3MnOllGdCrWGT4I8IoVf8Mc2cW7DzXqg3EwQPq3qo=";
          };
          # Universal binary?
          "aarch64-darwin" = x86_64-darwin;
        }."${system}" or (throw "Unsupported platform");
        file = pkgs.fetchurl url-and-hash;
      in pkgs.runCommandLocal "openshift-install" {
        nativeBuildInputs = [ pkgs.gnutar ];
        src = file;
      } ''
        mkdir -p "$out"/bin
        tar -zxf "$src" -C "$out"/bin
      '';

      kubectl-slice = let
        url-and-hash = {
          "x86_64-linux" = {
            url = "https://github.com/patrickdappollonio/kubectl-slice/releases/download/v1.1.0/kubectl-slice_1.1.0_linux_x86_64.tar.gz";
            hash = "sha256-DKI8WQU7KOqlKosUNno4o61I6KSblUm3CHWPHAEMz/k=";
          };
          "x86_64-darwin" = {
            url = "https://github.com/patrickdappollonio/kubectl-slice/releases/download/v1.1.0/kubectl-slice_1.1.0_darwin_x86_64.tar.gz";
            sha256 = pkgs.lib.fakeHash;
          };
          "aarch64-darwin" = {
            url = "https://github.com/patrickdappollonio/kubectl-slice/releases/download/v1.1.0/kubectl-slice_1.1.0_darwin_arm64.tar.gz";
            sha256 = "sha256-mjqCD5jnBXk496IXOeakxvQ7jW8Js1MlHFxLmd76Wf8=";
          };
        }."${system}" or (throw "Unsupported platform");
        file = pkgs.fetchurl url-and-hash;
      in pkgs.runCommandLocal "kubectl-slice" {
        src = file;
        nativeBuildInputs = [ pkgs.gnutar ];
      } ''
        mkdir -p "$out"/bin
        tar -zxf "$src" -C "$out"/bin
      '';
    };

    # nix run .#terraform-fhs --
    # nix run .#bmc-access --
    # nix run .#openshift-install --
    apps = {
      bmc-access = {
        type = "app";
        program = toString (import ./scripts/bmc-access.nix { inherit nixpkgs; }).bmc;
      };
      terraform-fhs = {
        type = "app";
        program = "${terraformFHS}/bin/${terraformFHS.meta.mainProgram}";
      };
      openshift-install = {
        type = "app";
        program = "${self.packages.${system}.openshift-install}/bin/openshift-install";
      };
    };

    devShell = pkgs.mkShell {
      name = "dev";

      nativeBuildInputs = [
        sops-nix.sops-import-keys-hook
      ];

      KUSTOMIZE_PLUGIN_HOME = pkgs.buildEnv {
        name = "kustomize-plugins";
        paths =  [ pkgs.kustomize-sops ];
        postBuild = ''
          mv $out/lib/* $out
          rm -r $out/lib
        '';
        pathsToLink = [ "/lib" ];
      };

      buildInputs = [
        deploy-rs.defaultPackage.${system}
        terraform
        sops-nix.ssh-to-pgp
        pkgs.ansible_2_13
        pkgs.jsonnet
        pkgs.jsonnet-bundler
        pkgs.kubectl
        pkgs.kubectx
        pkgs.kubernetes-helm
        pkgs.kubetail
        # pkgs.kustomize_3
        pkgs.kustomize
        # pkgs.ltrace
        pkgs.pipenv
        pkgs.python311
        pkgs.sops
        pkgs.openshift

        self.packages.${system}.openshift-install
        self.packages.${system}.kubectl-slice
      ];

      /*
      SFPATH =
        (pkgs.runCommandLocal "zsh-kubectl-completions" { buildInputs = [ pkgs.kubectl pkgs.installShellFiles ]; } ''
          kubectl completion zsh > kubectl.zsh
          kubectl completion bash > kubectl.bash
          installShellCompletion kubectl.{zsh,bash}
        '');
      */

      shellHook = ''
        export KUBECONFIG=$PWD/kubeconfig
      '';
        # export XDG_DATA_DIRS="''${XDG_DATA_DIRS-}''${XDG_DATA_DIRS+:}$SFPATH/share/bash-completions/completions"
        # . ${pkgs.bash-completion}/etc/profile.d/bash_completion.sh
        # if [ -n "''${ZSH_VERSION:-}" ]; then
        #  export fpath=($fpath $SFPATH/share/zsh/site-functions)
        # fi
    };
  });
}
