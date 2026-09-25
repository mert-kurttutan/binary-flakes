# binary-flakes

Nix packages for prebuilt Linux binaries with automated release updates.

## Packages

<!-- BEGIN PACKAGE TABLE -->
| Package | Version | Supported systems |
| --- | --- | --- |
| `codex` | `0.157.0` | `x86_64-linux` |
| `obsidian` | `1.13.7` | `x86_64-linux`, `aarch64-linux` |
| `zed` | `1.21.0` | `x86_64-linux`, `aarch64-linux` |
| `proton-pass-cli` | `2.4.1` | `x86_64-linux`, `aarch64-linux` |
| `proton-pass` | `1.40.2` | `x86_64-linux` |
<!-- END PACKAGE TABLE -->

Packages are built from upstream binary uploads.

## Usage

Build one or more packages with Nix:

```sh
nix build .#codex
nix build .#obsidian .#zed
```

## Automated updates

The scheduled workflow checks upstream releases, uploads compressed assets to
`PACKAGE-vVERSION` GitHub releases, updates hashes, verifies builds, and opens
update pull requests.

## Local updates

Check for a new version without downloading binaries:

```sh
nu scripts/check-updates.nu --package codex
nu scripts/check-updates.nu --package zed
```

For a package update, first repack its assets, then update the package
definition:

```sh
nu scripts/repack-release.nu obsidian --version 1.13.7
nu scripts/update.nu --package obsidian --version 1.13.7
```
