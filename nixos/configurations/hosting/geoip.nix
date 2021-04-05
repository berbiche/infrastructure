{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  geoipFolder = config.services.geoip-updater.databaseDir;
in
{
  config = lib.mkIf cfg.enable {
    services.geoip-updater = {
      enable = true;
      databases = [
        # "GeoLiteCountry/GeoIP.dat.gz"
        # "GeoIPv6.dat.gz"
        # "GeoLiteCity.dat.xz"
        # "GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz"
        "GeoLite2-Country.mmdb.gz"
        "GeoLite2-City.mmdb.gz"
      ];
    };

    services.nginx.package = pkgs.nginxStable.override {
      configureFlags = [ "--add-module=${pkgs.ngx_http_geoip2_module}" ];
      buildInputs = [ pkgs.libmaxminddb ];
    };

    services.nginx.appendHttpConfig = ''
      geoip2 ${geoipFolder}/GeoLite2-Country.mmdb {
        auto_reload 5m;
        $geoip2_metadata_country_build metadata build_epoch;
        $geoip2_data_country_code country iso_code;
        $geoip2_data_country_name country names en;
        $geoip2_data_continent_code continent code;
        $geoip2_data_continent_name continent names en;
      }
      geoip2 ${geoipFolder}/GeoLite2-City.mmdb {
        auto_reload 5m;
        $geoip2_data_city_name city names en;
        $geoip2_data_lat location latitude;
        $geoip2_data_lon location longitude;
      }
      geoip2 ${geoipFolder}/GeoLite2-ASN.mmdb {
        auto_reload 5m;
        $geoip2_data_asn autonomous_system_number;
        $geoip2_data_asorg autonomous_system_organization;
      }
    '';
  };
}
