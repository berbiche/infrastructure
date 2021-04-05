final: prev:
let
  unstable = import final.inputs.nixpkgs-unstable {
    config.allowUnfree = true;
    inherit (final) system;
  };
in
{
  ngx_http_geoip2_module = prev.stdenv.mkDerivation rec {
    pname = "ngx_http_geoip2_module";
    version = "3.3";

    src = prev.fetchFromGitHub {
      repo = pname;
      owner = "leev";
      rev = version;
      sha256 = "";
    };

    dontFixup = true;

    installPhase = ''
      mkdir $out
      cp *.c config $out
    '';
  };

  # Traefik's WebUI is broken on 20.09
  traefik = unstable.traefik;

  # Use the latest versions for these
  jackett = unstable.jackett;
  plex = unstable.plex;
  radarr = unstable.radarr;
  sonarr = unstable.sonarr;
  qbittorrent = unstable.qbittorrent;
}
