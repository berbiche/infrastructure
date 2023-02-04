{ inputs, rootPath }:

let
  targetSystem = "x86_64-linux";

  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  activateNixos = inputs.deploy-rs.lib.${targetSystem}.activate.nixos;

  makeHost = host: lib.nixosSystem {
    system = targetSystem;
    modules = [
      inputs.sops-nix.nixosModule
      (./. + "/${host}")
    ] ++ lib.concatLists [
      (import ../configurations)
      (import ../modules)
    ];
    specialArgs = {
      inherit (inputs) self;
      inherit inputs rootPath;
    };
    pkgs = import nixpkgs {
      system = targetSystem;
      overlays = builtins.attrValues inputs.self.overlays;
      config.allowUnfree = true;
    };
  };
in
rec {
  nixosConfigurations = lib.flip lib.genAttrs makeHost [
    "keanu"
  ];

  deploy.nodes = let
    makeNode = x: {
      sshOpts = [ "-p" "59910" ];
      hostname = "proxmox-${x}";
      fastConnection = false;
      profilesOrder = [ "system" ];
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = activateNixos nixosConfigurations.${x};
      };
    };
    generatedNodes = lib.flip lib.genAttrs makeNode [
      "keanu"
    ];
  in
    lib.recursiveUpdate generatedNodes {
      # apoc.profiles.system.autoRollback = false;
      # apoc.profiles.system.magicRollback = false;

      keanu.hostname = "keanu.ovh";
    };
}
