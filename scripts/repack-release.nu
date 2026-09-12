#!/usr/bin/env nu

use lib/common.nu [require-command]

# Explicitly opt-in: this command downloads upstream binaries and is not used
# by metadata-only update checks. It creates reproducible tar.zst assets for a
# release in this flake's repository.
const OBSIDIAN_REPO = "obsidianmd/obsidian-releases"

def main [
  package: string
  --version: string
  --output-dir: string = ".release-assets"
  --repository: string = ""
] {
  require-command curl; require-command gh; require-command mktemp; require-command tar; require-command zstd
  if $package != "obsidian" { error make "Only obsidian repacking is configured" }
  let target_repo = if ($repository | is-empty) { error make "Pass --repository owner/name to publish assets" } else { $repository }
  let output = ($output_dir | path expand)
  mkdir $output
  let work = (mktemp --directory | str trim)
  let tag = $"v($version)"
  try {
    for pair in [[x86_64 obsidian-($version).tar.gz] [aarch64 obsidian-($version)-arm64.tar.gz]] {
      let arch = $pair.0; let asset = $pair.1
      let source = $"https://github.com/($OBSIDIAN_REPO)/releases/download/($tag)/($asset)"
      ^curl --fail --location --show-error --silent $source --output $"($work)/($asset)"
      mkdir $"($work)/($arch)"
      ^tar --extract --gzip --file $"($work)/($asset)" --directory $"($work)/($arch)"
      ^tar --create --file - --directory $"($work)/($arch)" --sort=name --owner=0 --group=0 --numeric-owner --mtime="UTC 1970-01-01" . | ^zstd --compress --ultra --threads=0 -19 -f -o $"($output)/obsidian-linux-($arch).tar.zst"
    }
  } finally { rm --recursive --force $work }
  print $"Created assets in ($output). Publish them with: gh release upload v($version) ($output)/*.tar.zst --repo ($target_repo)"
}
