{ stdenv, fetchurl, lib }:

stdenv.mkDerivation rec {
  pname = "1panel";
  version = "2.1.12";

  src = fetchurl {
    url = "https://resource.1panel.pro/v2/stable/v${version}/release/1panel-v${version}-linux-amd64.tar.gz";
    hash = "sha256-71YH0Cwkn70BcGYMu5V2+anZH2Yd6DRPQ/QyivcXPz8=";
  };

  installPhase = ''
    mkdir -p $out/bin $out/share/1panel/geo $out/share/1panel/lang $out/share/1panel/initscript
    install -m755 1panel-core $out/bin/
    install -m755 1panel-agent $out/bin/
    install -m755 1pctl $out/bin/
    cp GeoIP.mmdb $out/share/1panel/geo/
    cp -r lang/* $out/share/1panel/lang/
    cp -r initscript/* $out/share/1panel/initscript/
  '';

  meta = with lib; {
    description = "Modern open-source Linux server management panel";
    homepage = "https://1panel.pro";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
