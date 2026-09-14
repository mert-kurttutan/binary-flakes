# binary-flakes

Nix packages for prebuilt binary releases, with release metadata and update
automation written in modular Nushell.

Packages currently covered:

- `codex`: OpenAI’s native x86_64 Linux Rust binary and code-mode host (`.zst` assets)
- `obsidian`: Linux desktop tarballs for x86_64 and aarch64
- `zed`: Linux editor tarballs for x86_64 and aarch64
- `proton-pass-cli`: Proton's native Linux CLI binaries, repacked as `.zst` assets

Obsidian, Zed, and Proton Pass target `x86_64-linux` and `aarch64-linux`; Codex targets only
`x86_64-linux`. The default package is Codex on x86_64 and Obsidian on
aarch64.

The hourly workflow checks Codex, Obsidian, Zed, and Proton Pass independently with Nushell. For
each new version it downloads upstream assets, publishes zstd-compressed files
to this repository's `PACKAGE-vVERSION` GitHub release,
updates hashes in the package definition, verifies Linux builds, and opens an
update pull request. Codex's two native assets are already zstd-compressed
upstream; the Obsidian and Zed tarballs are repacked as `.tar.zst`.

To backfill an unpublished current version, dispatch the workflow with `force` enabled.
To select a specific version, choose one package in the dispatch form. Locally:

```sh
nu scripts/check-updates.nu --package codex
nu scripts/check-updates.nu --package proton-pass-cli
nu scripts/repack-release.nu obsidian --version 1.13.7
nu scripts/update.nu --package obsidian --version 1.13.7
nu scripts/repack-release.nu zed --version 1.19.2
nu scripts/update.nu --package zed --version 1.19.2
nu scripts/repack-release.nu proton-pass-cli --version 2.3.3
nu scripts/update.nu --package proton-pass-cli --version 2.3.3
```

The repack command writes `.release-assets/manifest.json` with hashes of the
produced files. It does not publish assets itself. The workflow performs the
release upload before Nix build verification so the flake can fetch its own
assets. Version checks do not download binaries.
