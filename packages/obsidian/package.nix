{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, zstd, glib, nss, nspr
, atk, cups, dbus, expat, gtk3, pango, cairo, alsa-lib, libdrm, mesa
, libxkbcommon, libX11, libXcomposite, libXdamage, libXext, libXfixes
, libXrandr }:
let
  version = "1.13.7";
  sources = {
    x86_64-linux = {
      asset = "obsidian-linux-x86_64.tar.zst";
      hash = "sha256-BRVvCaHqwLxnc3rqBMgv78cZlIQF2KlSp0gC5dpyaYs=";
    };
    aarch64-linux = {
      asset = "obsidian-linux-aarch64.tar.zst";
      hash = "sha256-SxrIWZqidpp+7AxxVib0ajaODmXTNGwOuJYbwj1xa0s=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/obsidian-v${version}/${source.asset}";
    hash = source.hash;
  };
in stdenv.mkDerivation {
  pname = "obsidian";
  inherit version src;
  nativeBuildInputs = [ autoPatchelfHook makeWrapper zstd ];
  buildInputs = [ alsa-lib atk cairo cups dbus expat glib gtk3 libdrm libX11 libXcomposite libXdamage libXext libXfixes libXrandr libxkbcommon mesa nspr nss pango ];
  unpackPhase = ''
    runHook preUnpack
    tar --zstd -xf $src
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
