#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root log-info]
use lib/github.nu [asset-hash latest-manifest-version latest-tag release-assets]
use lib/nix.nu [npm-integrity replace-binding-hash replace-map-hash replace-version]

const CODEX_NATIVE = [aarch64-apple-darwin x86_64-apple-darwin x86_64-unknown-linux-musl aarch64-unknown-linux-musl]
const CODEX_NODE = [darwin-arm64 darwin-x64 linux-x64 linux-arm64]

def update-codex [version: string] {
  let base = $"https://github.com/openai/codex/releases/download/rust-v($version)"
  let original = open --raw codex.nix
  mut content = replace-version $original $version
  for platform in $CODEX_NATIVE {
    log-info $"Fetching hash for codex-($platform).zst"
    $content = replace-map-hash $content nativeHashes $platform (asset-hash openai/codex $"rust-v($version)" $"codex-($platform).zst")
  }
  for platform in $CODEX_NATIVE {
    log-info $"Fetching hash for code-mode-host-($platform).zst"
    $content = replace-map-hash $content codeModeHostHashes $platform (asset-hash openai/codex $"rust-v($version)" $"codex-code-mode-host-($platform).zst")
  }
  for platform in $CODEX_NODE {
    log-info $"Fetching hash for codex-npm-($platform).tgz"
    $content = replace-map-hash $content nodeOptionalDepHashes $platform (asset-hash openai/codex $"rust-v($version)" $"codex-npm-($platform)-($version).tgz")
  }
  log-info "Reading npm package integrity metadata"
  $content = replace-binding-hash $content npmTarball (npm-integrity "@openai/codex" $version)
  $content | save --force codex.nix
}

def update-obsidian [version: string] {
  let assets = release-assets obsidianmd/obsidian-releases $"v($version)"
  let expected = ["obsidian-($version).tar.gz" "obsidian-($version)-arm64.tar.gz"]
  for asset in $expected {
    if $asset not-in $assets { error make $"Missing Obsidian release asset: ($asset)" }
  }
  let original = open --raw obsidian.nix
  mut content = replace-version $original $version
  for asset in $expected {
    let key = if ($asset | str contains "arm64") { "aarch64-linux" } else { "x86_64-linux" }
    log-info $"Fetching hash for ($asset)"
    $content = replace-map-hash $content sources $key (asset-hash obsidianmd/obsidian-releases $"v($version)" $asset)
  }
  $content | save --force obsidian.nix
}

def main [
  --package: string = "codex"
  --version: string = ""
  --check
] {
  ensure-repository-root
  let repository = { codex: "openai/codex", obsidian: "obsidianmd/obsidian-releases" }
  let prefix = { codex: "rust-v", obsidian: "v" }
  let file = { codex: "codex.nix", obsidian: "obsidian.nix" }
  let current = current-version ($file | get $package)
  let target = if ($version | is-empty) {
    if $package == "obsidian" {
      latest-manifest-version "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json" latestVersion
    } else { latest-tag ($repository | get $package) ($prefix | get $package) }
  } else { $version }
  log-info $"($package): ($current) -> ($target)"
  if $current == $target { exit 0 }
  if $check { exit 1 }
  if $package == "codex" { update-codex $target } else if $package == "obsidian" { update-obsidian $target } else { error make $"Unknown package: ($package)" }
  log-info "Metadata updated. Build verification is a separate CI step."
}
