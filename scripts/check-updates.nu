#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]
use lib/github.nu [latest-manifest-version latest-tag]

def main [
  --package: string = "codex" # codex or obsidian
  --version: string = ""
] {
  ensure-repository-root
  let config = {
    codex: { file: "codex.nix", repository: "openai/codex", prefix: "rust-v" }
    obsidian: { file: "obsidian.nix", repository: "obsidianmd/obsidian-releases", prefix: "v" }
  }
  let selected = ($config | get $package)
  let current = current-version $selected.file
  let latest = if ($version | is-empty) {
    if $package == "obsidian" {
      latest-manifest-version "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json" latestVersion
    } else { latest-tag $selected.repository $selected.prefix }
  } else { $version }
  print $"current_version=($current)"
  print $"new_version=($latest)"
  print $"update_needed=($current != $latest)"
}
