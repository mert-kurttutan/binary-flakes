{ lib, stdenv, fetchurl, installShellFiles
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
, zstd }:
let
  version = "0.157.1";
  platform = "x86_64-unknown-linux-musl";
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${platform}.tar.zst";
    hash = "sha256-9D+bmwubY2jdyXt31Ddpba/MrKc2ANRt9bipszyKUCo=";
  };
in
assert stdenv.hostPlatform.system == "x86_64-linux" || throw "Codex is only packaged for x86_64-linux";
stdenv.mkDerivation {
  pname = "codex";
  inherit version;
  dontUnpack = true;
  dontPatchELF = true;
  dontStrip = true;
  nativeBuildInputs = [ zstd ] ++ lib.optionals installShellCompletions [ installShellFiles ];
  installPhase = ''
    mkdir -p $out
    tar --zstd -xf ${src} -C $out
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
