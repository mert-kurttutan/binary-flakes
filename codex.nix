{ lib, stdenv, fetchurl, nodejs_22, cacert, makeWrapper, installShellFiles
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
, zstd, openssl, libcap, libz, bubblewrap, runtime ? "native"
, nativeBinName ? "codex", nodeBinName ? "codex-node" }:
let
  version = "0.154.0";
  platformMap = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
  };
  nodePlatformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };
  platform = platformMap.${stdenv.hostPlatform.system} or null;
  nodePlatform = nodePlatformMap.${stdenv.hostPlatform.system} or null;
  nativeHashes = {
    "aarch64-apple-darwin" = "sha256-NsWJXVmjdajY6KkFhggOUsH16kIuyn/vrd71/b5SVH8=";
    "x86_64-apple-darwin" = "sha256-7xeTqgVWwPap31etrqS+O8UhVrWUoPgv9nyvtGW0d8U=";
    "x86_64-unknown-linux-musl" = "sha256-vq5qSDBd9v0hyLOUiakA96mjVheTPuawl1vP21tUKSU=";
    "aarch64-unknown-linux-musl" = "sha256-nWFedFoM3UOvSiYF4vvRK7MU022GbizDaLrW9t5lXcM=";
  };
  codeModeHostHashes = {
    "aarch64-apple-darwin" = "sha256-dXDi1vtPXeVr1/P339Z4Pm3UNGWqUMAO2nKCKUBQuTs=";
    "x86_64-apple-darwin" = "sha256-y+qv3kWHnqMLTT2fGyxgJttJWNnJntZ82zSMtzVdP38=";
    "x86_64-unknown-linux-musl" = "sha256-ZE/EprgWL43eqE7i40YcMey6de5GDu2msrdnq91m58c=";
    "aarch64-unknown-linux-musl" = "sha256-/U86GHAS1WXtjb89tlr68Hv+9ctIDYky4voY1k8QzTM=";
  };
  nodeOptionalDepHashes = {
    "darwin-arm64" = "sha256-KphmLXkxalmZPHIz4+JaGqHULaS0WQRYXTOlp9ocreE=";
    "darwin-x64" = "sha256-ksSTUzxTxDPE2UJSJR2rpPN5zLoGqZZNJgq7R6U13OE=";
    "linux-x64" = "sha256-4nyDpJ5gMWhe5/lWwSqtXxZITTqAGB3T/qkw+5azgys=";
    "linux-arm64" = "sha256-ojFbX2S/6v95tx4NNVBbqMIswelsq53JULYUyAQQWyQ=";
  };
  native = if runtime == "native" && platform != null then fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${platform}.zst";
    hash = nativeHashes.${platform};
  } else null;
  host = if runtime == "native" && platform != null then fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-${platform}.zst";
    hash = codeModeHostHashes.${platform};
  } else null;
  npm = if runtime == "node" then fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";
    hash = "sha256-hwZj1OZQQt01gwXpaiKvWHCKKDF81OdKhaqGfGn1hZs=";
  } else null;
  optionalDep = if runtime == "node" && nodePlatform != null then fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-npm-${nodePlatform}-${version}.tgz";
    hash = nodeOptionalDepHashes.${nodePlatform};
  } else null;
  runtimeConfig = {
    native = {
      nativeBuildInputs = [ zstd makeWrapper ];
      buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ openssl libcap libz ];
      description = "OpenAI Codex CLI (native binary)";
      binName = nativeBinName;
    };
    node = {
      nativeBuildInputs = [ nodejs_22 cacert makeWrapper ];
      buildInputs = [];
      description = "OpenAI Codex CLI (Node.js)";
      binName = nodeBinName;
    };
  };
  selected = runtimeConfig.${runtime};
  linuxRuntimePath = lib.makeBinPath (lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ]);
  generateShellCompletions = installShellCompletions && runtime == "native" && selected.binName == "codex";
  nativeBuild = runtime == "native";
in assert runtime == "native" -> platform != null || throw "Unsupported native platform: ${stdenv.hostPlatform.system}";
stdenv.mkDerivation {
  pname = if nativeBuild then "codex" else "codex-node";
  inherit version;
  dontUnpack = true;
  dontPatchELF = nativeBuild;
  dontStrip = nativeBuild;
  nativeBuildInputs = selected.nativeBuildInputs ++ lib.optionals generateShellCompletions [ installShellFiles ];
  buildInputs = selected.buildInputs;
  buildPhase = if nativeBuild then ''
    mkdir -p build
    zstd -d ${native} -o build/codex
    chmod +x build/codex
    zstd -d ${host} -o build/codex-code-mode-host
    chmod +x build/codex-code-mode-host
  '' else ''
    export HOME=$TMPDIR
    mkdir -p $out/lib/node_modules/@openai
    tar -xzf ${npm} -C $out/lib/node_modules/@openai
    mv $out/lib/node_modules/@openai/package $out/lib/node_modules/@openai/codex
    ${lib.optionalString (optionalDep != null) ''
      tar -xzf ${optionalDep} -C $out/lib/node_modules/@openai
      mv $out/lib/node_modules/@openai/package $out/lib/node_modules/@openai/codex-${nodePlatform}
    ''}
  '';
  installPhase = if nativeBuild then ''
    mkdir -p $out/bin $out/libexec
    install -m755 build/codex $out/libexec/codex
    install -m755 build/codex-code-mode-host $out/libexec/codex-code-mode-host
    ln -s ../libexec/codex-code-mode-host $out/bin/codex-code-mode-host
    makeWrapper $out/libexec/${selected.binName} $out/bin/${selected.binName} \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/${selected.binName}"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenv.hostPlatform.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}
  '' else ''
    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/${selected.binName} \
      --add-flags --no-warnings \
      --add-flags "$out/lib/node_modules/@openai/codex/bin/codex.js" \
      --set NODE_PATH "$out/lib/node_modules" \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/${selected.binName}"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenv.hostPlatform.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}
  '';
  postInstall = lib.optionalString generateShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <("$out/bin/${selected.binName}" completion bash) \
      --fish <("$out/bin/${selected.binName}" completion fish) \
      --zsh <("$out/bin/${selected.binName}" completion zsh)
  '';
  meta = with lib; {
    description = if nativeBuild then "OpenAI Codex CLI (native binary)" else "OpenAI Codex CLI (Node.js)";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = if nativeBuild then [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ] else platforms.all;
    mainProgram = selected.binName;
  };
}
