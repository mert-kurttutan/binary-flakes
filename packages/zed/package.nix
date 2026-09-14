{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib, fontconfig, glib
, gnutar, libxkbcommon, libx11, libxcb, makeWrapper, openssl
, vulkan-loader, wayland, zstd }:
let
  version = "1.19.2";
  sources = {
    x86_64-linux = {
      asset = "zed-linux-x86_64.tar.zst";
      hash = "sha256-60AgA+gFya7jkJxa+Aez4fe2RpdCI/c64YiXZUu5X6g=";
    };
    aarch64-linux = {
      asset = "zed-linux-aarch64.tar.zst";
      hash = "sha256-0iHtE+IMiAshpDsF/sFchNluHmRhgcur2KAleOCw7IA=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/zed-v${version}/${source.asset}";
    hash = source.hash;
  };
in stdenv.mkDerivation {
  pname = "zed";
  inherit version src;
  nativeBuildInputs = [ autoPatchelfHook gnutar makeWrapper zstd ];
  buildInputs = [ alsa-lib fontconfig glib libxkbcommon openssl stdenv.cc.cc vulkan-loader wayland libx11 libxcb ];
  dontUnpack = true;
  buildPhase = ''
    runHook preBuild
    mkdir -p build
    tar --zstd -xf $src -C build
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/zed $out/bin $out/share
    cp -r build/* $out/opt/zed/
    cp -r build/zed.app/share/. $out/share/
    zed_bin=$(find $out/opt/zed -type f -name zed -perm -u+x | head -n 1)
    test -n "$zed_bin"
    makeWrapper "$zed_bin" "$out/bin/zed" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader wayland glib libxkbcommon libx11 libxcb ]}
    runHook postInstall
  '';
  meta = with lib; {
    description = "Zed editor (prebuilt Linux binary)";
    homepage = "https://zed.dev";
    license = licenses.unfreeRedistributable;
    platforms = builtins.attrNames sources;
    mainProgram = "zed";
  };
}
