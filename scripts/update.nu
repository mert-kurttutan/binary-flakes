#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]
use lib/github.nu [latest-manifest-version latest-tag]
use lib/nix.nu [replace-binding-hash replace-map-hash replace-version]

const NATIVE = [aarch64-apple-darwin x86_64-apple-darwin x86_64-unknown-linux-musl aarch64-unknown-linux-musl]
const NODE = [darwin-arm64 darwin-x64 linux-x64 linux-arm64]

def main [
  --package: string = "codex"
  --version: string = ""
  --asset-dir: string = ".release-assets"
  --check
] {
  ensure-repository-root
  if $package not-in [codex obsidian] { error make $"Unknown package: ($package)" }
  let file = if $package == "codex" { "codex.nix" } else { "obsidian.nix" }
  let current = current-version $file
  let target = if $version != "" { $version } else if $package == "codex" {
    latest-tag openai/codex rust-v
  } else {
    latest-manifest-version "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json" latestVersion
  }
  if $check {
    print $"current_version=($current)"
    print $"new_version=($target)"
    print $"update_needed=($current != $target)"
    return
  }
  let manifest = open $"($asset_dir)/manifest.json"
  if $manifest.package != $package or $manifest.version != $target {
    error make "Asset manifest package/version does not match requested update"
  }
  mut content = replace-version (open --raw $file) $target
  if $package == "codex" {
    for platform in $NATIVE {
      $content = replace-map-hash $content nativeHashes $platform ($manifest.hashes | get $"codex-($platform).zst")
      $content = replace-map-hash $content codeModeHostHashes $platform ($manifest.hashes | get $"codex-code-mode-host-($platform).zst")
    }
    for platform in $NODE {
      $content = replace-map-hash $content nodeOptionalDepHashes $platform ($manifest.hashes | get $"codex-npm-($platform)-($target).tar.zst")
    }
    $content = replace-binding-hash $content npm ($manifest.hashes | get $"codex-npm-($target).tar.zst")
  } else {
    for item in [{key: x86_64-linux, arch: x86_64} {key: aarch64-linux, arch: aarch64}] {
      $content = replace-map-hash $content sources $item.key ($manifest.hashes | get $"obsidian-linux-($item.arch).tar.zst")
    }
  }
  $content | save --force $file
}
