{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, zstd, keyutils, libgcc }:
let
  version = "2.3.3";
  sources = {
    x86_64-linux = {
      asset = "pass-cli-linux-x86_64.zst";
      hash = "sha256-m8jzZnnz8Tch0sK6jV9VikPwCrLZbD4t44qS+l6wegA=";
    };
    aarch64-linux = {
      asset = "pass-cli-linux-aarch64.zst";
      hash = "sha256-W7Y+/EA9ZIvVcmh78ynWZ4Zs8HcEBBFcga24ROH2hzA=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/proton-pass-cli-v${version}/${source.asset}";
    hash = source.hash;
  };
in stdenv.mkDerivation {
  pname = "proton-pass-cli";
  inherit version src;
  dontUnpack = true;
  dontStrip = true;
  nativeBuildInputs = [ autoPatchelfHook makeWrapper zstd ];
  buildInputs = [ keyutils libgcc ];
  buildPhase = ''
    runHook preBuild
    mkdir -p build
    zstd -d $src -o build/pass-cli
    chmod +x build/pass-cli
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 build/pass-cli $out/bin/pass-cli
    runHook postInstall
  '';
  postFixup = ''
    wrapProgram $out/bin/pass-cli --set PROTON_PASS_NO_UPDATE_CHECK 1
  '';
  meta = with lib; {
    description = "Command-line interface for managing Proton Pass vaults, items, and secrets";
    homepage = "https://github.com/protonpass/pass-cli";
    license = licenses.gpl3Plus;
    platforms = builtins.attrNames sources;
    mainProgram = "pass-cli";
  };
}
