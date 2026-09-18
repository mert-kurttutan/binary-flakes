{ lib, stdenv, fetchurl, makeWrapper, installShellFiles
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
, zstd, openssl, libcap, libz, bubblewrap }:
let
  version = "0.155.0";
  platform = "x86_64-unknown-linux-musl";
  native = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/codex-v${version}/codex-${platform}.zst";
    hash = "sha256-KnLTNS9euaWKYCaeszOPxai9uIBePewt+qlPRWmUFhM=";
  };
  host = fetchurl {
    url = "https://github.com/mert-kurttutan/binary-flakes/releases/download/codex-v${version}/codex-code-mode-host-${platform}.zst";
    hash = "sha256-wVJ5+APNIpVoql6D/W8w59sBwP2zxJQ1tYX1Ge0lDhk=";
  };
in
assert stdenv.hostPlatform.system == "x86_64-linux" || throw "Codex is only packaged for x86_64-linux";
stdenv.mkDerivation {
  pname = "codex";
  inherit version;
  dontUnpack = true;
  dontPatchELF = true;
  dontStrip = true;
  nativeBuildInputs = [ zstd makeWrapper ] ++ lib.optionals installShellCompletions [ installShellFiles ];
  buildInputs = [ openssl libcap libz ];
  buildPhase = ''
    mkdir -p build
    zstd -d ${native} -o build/codex
    chmod +x build/codex
    zstd -d ${host} -o build/codex-code-mode-host
    chmod +x build/codex-code-mode-host
  '';
  installPhase = ''
    mkdir -p $out/bin $out/libexec
    install -m755 build/codex $out/libexec/codex
    install -m755 build/codex-code-mode-host $out/libexec/codex-code-mode-host
    ln -s ../libexec/codex-code-mode-host $out/bin/codex-code-mode-host
    makeWrapper $out/libexec/codex $out/bin/codex \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/codex"' \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : "${lib.makeBinPath [ bubblewrap ]}"
  '';
  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <("$out/bin/codex" completion bash) \
      --fish <("$out/bin/codex" completion fish) \
      --zsh <("$out/bin/codex" completion zsh)
  '';
  meta = with lib; {
    description = "OpenAI Codex CLI (native x86_64 Linux binary)";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
