#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]
use lib/github.nu [latest-manifest-version latest-tag]
use lib/nix.nu [replace-binding-hash replace-map-hash replace-version]

const CODEX_PLATFORM = "x86_64-unknown-linux-musl"

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
    $content = replace-binding-hash $content native ($manifest.hashes | get $"codex-($CODEX_PLATFORM).zst")
    $content = replace-binding-hash $content host ($manifest.hashes | get $"codex-code-mode-host-($CODEX_PLATFORM).zst")
  } else {
    for item in [{key: x86_64-linux, arch: x86_64} {key: aarch64-linux, arch: aarch64}] {
      $content = replace-map-hash $content sources $item.key ($manifest.hashes | get $"obsidian-linux-($item.arch).tar.zst")
    }
  }
  $content | save --force $file
}
