{ config, rootPath, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption types;

  cfg = config.configurations.discord-bot.jmusicbot;
in
{
  options.configurations.discord-bot.jmusicbot = {
    enable = mkEnableOption "jmusicbot";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.virtualisation.docker.enable || config.virtualisation.podman.enable;
      message = "One of docker or Podman container configuration must be enabled";
    }];

    sops.secrets."jmusicbot.txt" = {
      format = "binary";
      mode = "0400";
      sopsFile = rootPath + "/secrets/jmusicbot.txt";
    };

    virtualisation.oci-containers = let
      dockerImage = pkgs.dockerTools.pullImage rec {
        imageName = "cocomine/jmusicbot";
        imageDigest = "sha256:29cf51018701932c02c9f06bb9d402ba5668f7c46ff4bec40a6c60829c7e7f4c";
        finalImageName = imageName;
        finalImageTag = "0.2.7_upward";
        sha256 = "sha256-W2TCwLL0kVThgTpgguxQIKZ4vvNlMDCAEamPhN3thgs=";
      };
      start-script = pkgs.writeTextFile {
        name = "start.sh";
        executable = true;
        text = ''
          #！/bin/bash
          cd bot;
          if [ ! -f JMusicBot-''${VERSION}.jar ]
          then
            wget https://github.com/jagrosh/MusicBot/releases/download/''${VERSION}/JMusicBot-''${VERSION}.jar;
          fi
          java -server -jar JMusicBot-''${VERSION}.jar nogui;
        '';
      };
    in {
      backend = "podman";
      containers = {
        discord-jmusicbot = {
          image = "cocomine/jmusicbot:0.2.7_upward";
          imageFile = dockerImage;
          # ports = [ "127.0.0.1:4181:4181" ];
          volumes = [
            "${config.sops.secrets."jmusicbot.txt".path}:/bot/config.txt:ro"
            "${start-script}:/start.sh:ro"
          ];
          entrypoint = "/bin/bash";
          cmd = [
            "-c"
            "cd / ; /start.sh"
          ];
          autoStart = true;
          environment = {
            # Release version
            VERSION = "0.3.6";
          };
        };
      };
    };
  };
}
