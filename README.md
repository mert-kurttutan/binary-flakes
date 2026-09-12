# binary-flakes

Nix packages for prebuilt binary releases, with release metadata and update
automation written in modular Nushell.

Packages currently covered:

- `codex`: OpenAI’s native Rust binary and its code-mode host (`.zst` assets)
- `codex-node`: the Node.js distribution and platform dependency archives
- `obsidian`: Linux desktop tarballs for x86_64 and aarch64

The published flake outputs currently target `x86_64-linux` and
`aarch64-linux`. Codex’s Darwin mappings remain in the package definition for
a future Darwin-compatible nixpkgs input.

The hourly workflow checks Codex and Obsidian independently with Nushell. For
each new version it downloads upstream assets, publishes zstd-compressed files
to this repository's `codex-vVERSION` or `obsidian-vVERSION` GitHub release,
updates hashes in the package definition, verifies Linux builds, and opens an
update pull request. Native Codex assets are already zstd-compressed upstream;
the Node and Obsidian tarballs are repacked as `.tar.zst`.

To backfill an unpublished current version, dispatch the workflow with `force` enabled.
To select a specific version, choose one package in the dispatch form. Locally:

```sh
nu scripts/check-updates.nu --package codex
nu scripts/repack-release.nu obsidian --version 1.13.7
nu scripts/update.nu --package obsidian --version 1.13.7
```

The repack command writes `.release-assets/manifest.json` with hashes of the
produced files. It does not publish assets itself. The workflow performs the
release upload before Nix build verification so the flake can fetch its own
assets. Version checks do not download binaries.
