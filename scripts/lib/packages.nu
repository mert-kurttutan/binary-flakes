use github.nu [latest-manifest-version latest-tag]

export def package-config [package: string] {
  let config = {
    codex: {file: "packages/codex/package.nix", repository: "openai/codex", prefix: "rust-v"}
    obsidian: {file: "packages/obsidian/package.nix", repository: "obsidianmd/obsidian-releases", prefix: "v"}
    zed: {file: "packages/zed/package.nix", repository: "zed-industries/zed", prefix: "v"}
    proton-pass-cli: {file: "packages/proton-pass-cli/package.nix", repository: "protonpass/pass-cli", prefix: "v"}
  }
  if $package not-in ($config | columns) { error make $"Unknown package: ($package)" }
  $config | get $package
}

export def target-version [package: string, override: string = ""] {
  if $override != "" { return $override }
  let config = package-config $package
  if $package == "obsidian" {
    latest-manifest-version "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json" latestVersion
  } else {
    latest-tag $config.repository $config.prefix
  }
}

export def tar-sources [package: string, version: string] {
  if $package == "zed" {
    [x86_64 aarch64] | each {|arch|
      {
        arch: $arch
        source: $"zed-linux-($arch).tar.gz"
        asset: $"zed-linux-($arch).tar.zst"
        url: $"https://github.com/zed-industries/zed/releases/download/v($version)/zed-linux-($arch).tar.gz"
      }
    }
  } else if $package == "obsidian" {
    [x86_64 aarch64] | each {|arch|
      let source = if $arch == "x86_64" { $"obsidian-($version).tar.gz" } else { $"obsidian-($version)-arm64.tar.gz" }
      {
        arch: $arch
        source: $source
        asset: $"obsidian-linux-($arch).tar.zst"
        url: $"https://github.com/obsidianmd/obsidian-releases/releases/download/v($version)/($source)"
      }
    }
  } else {
    error make $"No tarball sources configured for ($package)"
  }
}

export def binary-sources [package: string, version: string] {
  if $package == "proton-pass-cli" {
    [x86_64 aarch64] | each {|arch|
      {
        arch: $arch
        source: $"pass-cli-linux-($arch)"
        asset: $"pass-cli-linux-($arch).zst"
        url: $"https://proton.me/download/pass-cli/($version)/pass-cli-linux-($arch)"
      }
    }
  } else {
    error make $"No binary sources configured for ($package)"
  }
}
