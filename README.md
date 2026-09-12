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

The normal update path only queries release metadata. Hash refreshes use
published release digests; repacking is explicit because it downloads large
binaries:

```sh
nu scripts/check-updates.nu --package codex
nu scripts/update.nu --package codex --check
nu scripts/update.nu --package obsidian --version 1.13.7
nu scripts/repack-release.nu obsidian --version 1.13.7 --repository owner/repo
```

After metadata changes, verify with `nix flake check` and the relevant
`nix build` targets in the later asset/build job. No large release asset is
downloaded during metadata checks or digest-based hash refreshes.
