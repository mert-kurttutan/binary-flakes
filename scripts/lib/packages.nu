use github.nu [latest-manifest-version latest-tag]
use common.nu [require-command]

export def package-config [package: string] {
  let config = {
    codex: {file: "packages/codex/package.nix", repository: "openai/codex", prefix: "rust-v"}
    obsidian: {file: "packages/obsidian/package.nix", repository: "obsidianmd/obsidian-releases", prefix: "v"}
    zed: {file: "packages/zed/package.nix", repository: "zed-industries/zed", prefix: "v"}
    proton-pass-cli: {file: "packages/proton-pass-cli/package.nix", repository: "protonpass/pass-cli", prefix: "v"}
    proton-pass: {file: "packages/proton-pass/package.nix", repository: "", prefix: ""}
  }
  if $package not-in ($config | columns) { error make $"Unknown package: ($package)" }
  $config | get $package
}

export def target-version [package: string, override: string = ""] {
  if $override != "" { return $override }
  let config = package-config $package
  match $package {
    "obsidian" => {
      latest-manifest-version "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json" latestVersion
    }
    "proton-pass" => {
      require-command curl
      let response = (^curl --fail --location --ipv4 --http1.1 --retry 3 --retry-all-errors --show-error --silent --user-agent "Mozilla/5.0" "https://proton.me/download/PassDesktop/linux/x64/version.json" | complete)
      if $response.exit_code != 0 { error make ($response.stderr | str trim) }
      let manifest = ($response.stdout | from json)
      $manifest.Releases | where CategoryName == "Stable" | first | get Version
    }
    _ => {
      latest-tag $config.repository $config.prefix
    }
  }
}

export def tar-sources [package: string, version: string] {
  let _input = $in
  match $package {
    "zed" => {
      mut sources = []
      for arch in [x86_64 aarch64] {
        let entry = {
          arch: $arch
          source: $"zed-linux-($arch).tar.gz"
          asset: $"zed-linux-($arch).tar.zst"
          url: $"https://github.com/zed-industries/zed/releases/download/v($version)/zed-linux-($arch).tar.gz"
        }
        $sources = ($sources ++ [$entry])
      }
      $sources
    }
    "obsidian" => {
      mut sources = []
      for arch in [x86_64 aarch64] {
        let source = if $arch == "x86_64" { $"obsidian-($version).tar.gz" } else { $"obsidian-($version)-arm64.tar.gz" }
        let entry = {
          arch: $arch
          source: $source
          asset: $"obsidian-linux-($arch).tar.zst"
          url: $"https://github.com/obsidianmd/obsidian-releases/releases/download/v($version)/($source)"
        }
        $sources = ($sources ++ [$entry])
      }
      $sources
    }
    _ => {
      error make $"No tarball sources configured for ($package)"
    }
  }
}

export def binary-sources [package: string, version: string] {
  let _input = $in
  match $package {
    "proton-pass-cli" => {
      mut sources = []
      for arch in [x86_64 aarch64] {
        let entry = {
          arch: $arch
          source: $"pass-cli-linux-($arch)"
          asset: $"pass-cli-linux-($arch).zst"
          url: $"https://proton.me/download/pass-cli/($version)/pass-cli-linux-($arch)"
        }
        $sources = ($sources ++ [$entry])
      }
      $sources
    }
    _ => {
      error make $"No binary sources configured for ($package)"
    }
  }
}

export def deb-sources [package: string, version: string] {
  let _input = $in
  match $package {
    "proton-pass" => {
      mut sources = []
      let entry = {
        arch: "x86_64"
        source: $"proton-pass_($version)_amd64.deb"
        asset: "proton-pass-linux-x86_64.tar.zst"
        url: $"https://proton.me/download/pass/linux/x64/proton-pass_($version)_amd64.deb"
      }
      $sources = ($sources ++ [$entry])
      $sources
    }
    _ => {
      error make $"No deb sources configured for ($package)"
    }
  }
}
