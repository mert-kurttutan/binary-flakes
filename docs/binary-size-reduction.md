# Binary size reduction

This repository republishes upstream Linux binaries in zstd level 19-compressed
release assets. The benchmark compares the size of each upstream delivery artifact with
the corresponding artifact produced by `repack-release.nu`.

Codex is excluded because its upstream files are already zstd-compressed.

Run the benchmark for all supported packages:

```sh
nu scripts/benchmark-size.nu
```

Run it for one package and an explicit version:

```sh
nu scripts/benchmark-size.nu --package proton-pass --version 1.40.2
```

For each package, the benchmark downloads the upstream artifact. If the
matching repacked asset is missing from `.release-assets/`, it automatically
runs `scripts/repack-release.nu` to create it, then compares byte sizes and
prints the original size, produced size, saved size, and percentage reduction.
It also writes the generated Markdown summary to
`docs/binary-size-reduction-results.md`. The total is calculated from the sum
of all compared artifacts.
