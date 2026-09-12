{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, zstd, glib, nss, nspr
, atk, cups, dbus, expat, gtk3, pango, cairo, alsa-lib, libdrm, mesa
, libxkbcommon, libX11, libXcomposite, libXdamage, libXext, libXfixes
, libXrandr }:
let
  version = "1.13.7";
  sources = {
    x86_64-linux = {
      asset = "obsidian-${version}.tar.gz";
      hash = "sha256-08vjdcv6QCTbGRC5gZFkn0E0xcSK7l5gtudxOYfc2yg=";
    };
    aarch64-linux = {
      asset = "obsidian-${version}-arm64.tar.gz";
      hash = "sha256-mKrDTR8TKjXPUG/D+hltWV3N7v3r1EsMxfqqehohDeI=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/${source.asset}";
    hash = source.hash;
  };
in stdenv.mkDerivation {
  pname = "obsidian";
  inherit version src;
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ alsa-lib atk cairo cups dbus expat glib gtk3 libdrm libX11 libXcomposite libXdamage libXext libXfixes libXrandr libxkbcommon mesa nspr nss pango ];
  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/obsidian $out/bin
    cp -r ./* $out/opt/obsidian/
    binary=$(find $out/opt/obsidian -type f -name obsidian -perm -u+x | head -n 1)
    test -n "$binary"
    makeWrapper "$binary" $out/bin/obsidian
    runHook postInstall
  '';
  meta = with lib; {
    description = "Obsidian note-taking application (prebuilt binary)";
    homepage = "https://obsidian.md";
    license = licenses.unfree;
    platforms = builtins.attrNames sources;
    mainProgram = "obsidian";
  };
}
