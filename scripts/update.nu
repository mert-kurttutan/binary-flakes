#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]
use lib/packages.nu [package-config target-version tar-sources binary-sources]
use lib/nix.nu [replace-binding-hash replace-map-hash replace-version]

const CODEX_PLATFORM = "x86_64-unknown-linux-musl"

def main [
  --package: string = "codex"
  --version: string = ""
  --asset-dir: string = ".release-assets"
  --check
] {
  ensure-repository-root
  let file = (package-config $package).file
  let current = current-version $file
  let target = target-version $package $version
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
  match $package {
    "codex" => {
      $content = replace-binding-hash $content src ($manifest.hashes | get $"codex-package-($CODEX_PLATFORM).tar.zst")
    }
    "proton-pass-cli" => {
      for item in (binary-sources $package $target) {
        $content = replace-map-hash $content sources $"($item.arch)-linux" ($manifest.hashes | get $item.asset)
      }
    }
    "proton-pass" => {
      $content = replace-binding-hash $content src ($manifest.hashes | get "proton-pass-linux-x86_64.tar.zst")
    }
    _ => {
      for item in (tar-sources $package $target) {
        $content = replace-map-hash $content sources $"($item.arch)-linux" ($manifest.hashes | get $item.asset)
      }
    }
  }
  $content | save --force $file
  ^nu scripts/generate-readme.nu
}
