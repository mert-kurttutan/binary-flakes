#!/usr/bin/env nu

use lib/common.nu [require-command]
use lib/packages.nu [package-config tar-sources binary-sources deb-sources]

const CODEX_PLATFORM = "x86_64-unknown-linux-musl"

def download [url: string, destination: string] {
  ^curl --fail --location --retry 3 --show-error --silent $url --output $destination
}

def repack-tar [source: string, destination: string, work: string] {
  mkdir $work
  ^tar -xzf $source -C $work
  ^tar -cf - -C $work --sort=name --owner=0 --group=0 --numeric-owner --mtime="UTC 1970-01-01" . | ^zstd -9 --threads=0 --force -o $destination
  ^tar --zstd -tf $destination | ignore
}

def repack-deb [source: string, destination: string, work: string] {
  let archive = $"($work)/deb-archive"
  let payload = $"($work)/payload"
  mkdir $archive
  mkdir $payload
  cd $archive
  ^ar x $source
  let data = (glob $"($archive)/data.tar.*" | first)
  ^tar -xf $data -C $payload
  ^tar -cf - -C $payload --sort=name --owner=0 --group=0 --numeric-owner --mtime="UTC 1970-01-01" . | ^zstd -9 --threads=0 --force -o $destination
  ^tar --zstd -tf $destination | ignore
}

def main [
  package: string
  --version: string
  --output-dir: string = ".release-assets"
] {
  for command in [curl ar tar zstd nix mktemp] { require-command $command }
  if $version == "" { error make "Pass --version" }
  package-config $package | ignore
  let output = ($output_dir | path expand)
  mkdir $output
  let work = (mktemp --directory | str trim)
  mut hashes = {}
  try {
    if $package == "codex" {
      let base = $"https://github.com/openai/codex/releases/download/rust-v($version)"
      for prefix in [codex codex-code-mode-host] {
        let name = $"($prefix)-($CODEX_PLATFORM).zst"
        download $"($base)/($name)" $"($output)/($name)"
        ^zstd --test $"($output)/($name)" | ignore
        $hashes = ($hashes | upsert $name (^nix hash file $"($output)/($name)" | str trim))
      }
    } else if $package == "proton-pass-cli" {
      for item in (binary-sources $package $version) {
        let raw = $"($work)/($item.source)"
        download $item.url $raw
        ^zstd -19 --quiet --force $raw -o $"($output)/($item.asset)"
        ^zstd --test $"($output)/($item.asset)" | ignore
        $hashes = ($hashes | upsert $item.asset (^nix hash file $"($output)/($item.asset)" | str trim))
      }
    } else if $package == "proton-pass" {
      for item in (deb-sources $package $version) {
        let raw = $"($work)/($item.source)"
        download $item.url $raw
        repack-deb $raw $"($output)/($item.asset)" $work
        $hashes = ($hashes | upsert $item.asset (^nix hash file $"($output)/($item.asset)" | str trim))
      }
    } else {
      for item in (tar-sources $package $version) {
        download $item.url $"($work)/($item.source)"
        repack-tar $"($work)/($item.source)" $"($output)/($item.asset)" $"($work)/($item.arch)"
        $hashes = ($hashes | upsert $item.asset (^nix hash file $"($output)/($item.asset)" | str trim))
      }
    }
    {package: $package, version: $version, hashes: $hashes} | to json | save --force $"($output)/manifest.json"
  } finally { rm --recursive --force $work }
}
