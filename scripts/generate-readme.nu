#!/usr/bin/env nu

use lib/common.nu [current-version ensure-repository-root]

const PACKAGES = [
  {name: "codex", file: "packages/codex/package.nix", systems: "`x86_64-linux`"}
  {name: "obsidian", file: "packages/obsidian/package.nix", systems: "`x86_64-linux`, `aarch64-linux`"}
  {name: "zed", file: "packages/zed/package.nix", systems: "`x86_64-linux`, `aarch64-linux`"}
  {name: "proton-pass-cli", file: "packages/proton-pass-cli/package.nix", systems: "`x86_64-linux`, `aarch64-linux`"}
]

def main [] {
  ensure-repository-root

  let rows = ($PACKAGES | each {|package|
    let version = current-version $package.file
    $"| `($package.name)` | `($version)` | ($package.systems) |"
  })

  let table = ([
    "<!-- BEGIN PACKAGE TABLE -->"
    "| Package | Version | Supported systems |"
    "| --- | --- | --- |"
    ...$rows
    "<!-- END PACKAGE TABLE -->"
  ] | str join "\n")

  let readme = open --raw README.md
  let pattern = '(?s)<!-- BEGIN PACKAGE TABLE -->.*?<!-- END PACKAGE TABLE -->'
  if not ($readme | str contains "<!-- BEGIN PACKAGE TABLE -->") {
    error make "README.md is missing the package table markers"
  }
  if not ($readme | str contains "<!-- END PACKAGE TABLE -->") {
    error make "README.md is missing the package table end marker"
  }

  $readme | str replace --regex $pattern $table | save --force README.md
}
