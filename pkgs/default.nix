final: prev: {
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

  traefik = final.inputs.nixpkgs-unstable.legacyPackages.${final.system}.traefik;
}
