{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, zstd
, alsa-lib, atk, cairo, cups, dbus, expat, gdk-pixbuf, glib, gtk3
, libdrm, libxkbcommon, libX11, libXcomposite, libXdamage, libXext
, libXfixes, libXrandr, mesa, nss, pango }:
let
  version = "1.40.2";
  src = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/proton-pass-v${version}/proton-pass-linux-x86_64.tar.zst";
    hash = "sha256-rNF09Kj5en2o6tTiys61+YNYJULKibP4z8JypGfWkuA=";
  };
in
assert stdenv.hostPlatform.system == "x86_64-linux" || throw "Proton Pass Desktop is only packaged for x86_64-linux";
stdenv.mkDerivation {
  pname = "proton-pass";
  inherit version src;
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook makeWrapper zstd ];
  buildInputs = [ alsa-lib atk cairo cups dbus expat gdk-pixbuf glib gtk3 libdrm libxkbcommon libX11 libXcomposite libXdamage libXext libXfixes libXrandr mesa nss pango ];
  buildPhase = ''
    mkdir -p build
    tar --zstd -xf $src -C build
  '';
  installPhase = ''
    mkdir -p $out/opt/proton-pass $out/bin $out/share
    cp -r build/* $out/opt/proton-pass/
    binary=$(find $out/opt/proton-pass -type f \( -name proton-pass -o -name 'Proton Pass' \) -perm -u+x | head -n 1)
    test -n "$binary"
    makeWrapper "$binary" $out/bin/proton-pass
    if [ -d $out/opt/proton-pass/usr/share ]; then
      cp -r $out/opt/proton-pass/usr/share/. $out/share/
    fi
  '';
  meta = with lib; {
    description = "Proton Pass desktop application (prebuilt binary)";
    homepage = "https://proton.me/pass";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "proton-pass";
  };
}
