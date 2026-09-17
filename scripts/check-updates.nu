#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]
use lib/packages.nu [package-config target-version]

def main [
  --package: string = "codex" # codex, obsidian, zed, proton-pass-cli, or proton-pass
  --version: string = ""
] {
  ensure-repository-root
  let selected = package-config $package
  let current = current-version $selected.file
  let latest = target-version $package $version
  print $"current_version=($current)"
  print $"new_version=($latest)"
  print $"update_needed=($current != $latest)"
}
