#!/usr/bin/env nu

use lib/common.nu [require-command]

const NATIVE = [aarch64-apple-darwin x86_64-apple-darwin x86_64-unknown-linux-musl aarch64-unknown-linux-musl]
const NODE = [darwin-arm64 darwin-x64 linux-x64 linux-arm64]

def download [url: string, destination: string] {
  ^curl --fail --location --retry 3 --show-error --silent $url --output $destination
}

def repack-tar [source: string, destination: string, work: string] {
  mkdir $work
  ^tar -xzf $source -C $work
  ^tar -cf - -C $work --sort=name --owner=0 --group=0 --numeric-owner --mtime="UTC 1970-01-01" . | ^zstd -9 --threads=0 --force -o $destination
  ^tar --zstd -tf $destination | ignore
}

def main [
  package: string
  --version: string
  --output-dir: string = ".release-assets"
] {
  for command in [curl tar zstd nix mktemp] { require-command $command }
  if $version == "" { error make "Pass --version" }
  if $package not-in [codex obsidian] { error make $"Unknown package: ($package)" }
  let output = ($output_dir | path expand)
  mkdir $output
  let work = (mktemp --directory | str trim)
  mut hashes = {}
  try {
    if $package == "codex" {
      let base = $"https://github.com/openai/codex/releases/download/rust-v($version)"
      for platform in $NATIVE {
        for prefix in [codex codex-code-mode-host] {
          let name = $"($prefix)-($platform).zst"
          download $"($base)/($name)" $"($output)/($name)"
          ^zstd --test $"($output)/($name)" | ignore
          $hashes = ($hashes | upsert $name (^nix hash file $"($output)/($name)" | str trim))
        }
      }
      let npm_name = $"codex-npm-($version).tar.zst"
      download $"https://registry.npmjs.org/@openai/codex/-/codex-($version).tgz" $"($work)/npm.tgz"
      repack-tar $"($work)/npm.tgz" $"($output)/($npm_name)" $"($work)/npm"
      $hashes = ($hashes | upsert $npm_name (^nix hash file $"($output)/($npm_name)" | str trim))
      for platform in $NODE {
        let name = $"codex-npm-($platform)-($version)"
        download $"($base)/($name).tgz" $"($work)/($name).tgz"
        repack-tar $"($work)/($name).tgz" $"($output)/($name).tar.zst" $"($work)/($platform)"
        $hashes = ($hashes | upsert $"($name).tar.zst" (^nix hash file $"($output)/($name).tar.zst" | str trim))
      }
    } else {
      let base = $"https://github.com/obsidianmd/obsidian-releases/releases/download/v($version)"
      for item in [{arch: x86_64, source: $"obsidian-($version).tar.gz"} {arch: aarch64, source: $"obsidian-($version)-arm64.tar.gz"}] {
        let name = $"obsidian-linux-($item.arch).tar.zst"
        download $"($base)/($item.source)" $"($work)/($item.source)"
        repack-tar $"($work)/($item.source)" $"($output)/($name)" $"($work)/($item.arch)"
        $hashes = ($hashes | upsert $name (^nix hash file $"($output)/($name)" | str trim))
      }
    }
    {package: $package, version: $version, hashes: $hashes} | to json | save --force $"($output)/manifest.json"
  } finally { rm --recursive --force $work }
}
