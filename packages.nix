{ pkgs, system, ... }:

{
  openshift-install = let
    url-and-hash = rec {
      "x86_64-linux" = {
        url = "https://github.com/okd-project/okd/releases/download/4.11.0-0.okd-2022-12-02-145640/openshift-install-linux-4.11.0-0.okd-2022-12-02-145640.tar.gz";
        hash = "";
      };
      "x86_64-darwin" = {
        url = "https://github.com/okd-project/okd/releases/download/4.11.0-0.okd-2022-12-02-145640/openshift-install-mac-4.11.0-0.okd-2022-12-02-145640.tar.gz";
        hash = "sha256-xg9Ljoroi4fcomS5juW4qEHufdWkuTIjSMJc3LF8Mrs=";
      };
      # Universal binary?
      # "aarch64-darwin" = {
      #   url = "https://github.com/okd-project/okd/releases/download/4.11.0-0.okd-2022-12-02-145640/openshift-install-mac-arm64-4.11.0-0.okd-2022-12-02-145640.tar.gz";
      #   hash = "sha256-6txY/VF9o7Jx6o7QURdGxJl1iH6sx/u50lUepjAh4N0=";
      # };
      "aarch64-darwin" = x86_64-darwin;
    }."${system}" or (throw "Unsupported platform");
    file = pkgs.fetchurl url-and-hash;
  in (pkgs.runCommandLocal "openshift-install" {
    nativeBuildInputs = [ pkgs.gnutar ];
    src = file;
  } ''
    mkdir -p "$out"/bin
    tar -zxf "$src" -C "$out"/bin
  '').overrideAttrs (drv: {
      meta = drv.meta or {} // {
        mainProgram = "openshift-install";
      };
    });

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
}
