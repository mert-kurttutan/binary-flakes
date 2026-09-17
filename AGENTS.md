# Update instructions

For `zed` and `proton-pass-cli`, use the same repack-and-update commands as the
README example, replacing the package name and version:

```sh
nu scripts/repack-release.nu zed --version 1.19.2
nu scripts/update.nu --package zed --version 1.19.2

nu scripts/repack-release.nu proton-pass-cli --version 2.3.3
nu scripts/update.nu --package proton-pass-cli --version 2.3.3
```

The repack command writes `.release-assets/manifest.json` with hashes of the
produced files. It does not publish a release. The manifest must exist before
running `update.nu`.
