use common.nu [require-command strip-prefix]

export def latest-tag [repository: string, prefix: string = "v"] {
  require-command gh
  let result = (^gh release view --repo $repository --json tagName -q '.tagName' | complete)
  if $result.exit_code != 0 { error make ($result.stderr | str trim) }
  strip-prefix $result.stdout $prefix
}

export def release-assets [repository: string, tag: string] {
  require-command gh
  let result = (^gh release view $tag --repo $repository --json assets --jq '.assets[].name' | complete)
  if $result.exit_code != 0 { error make ($result.stderr | str trim) }
  $result.stdout | lines
}

export def asset-hash [repository: string, tag: string, asset: string] {
  require-command gh
  require-command nix
  let query = ('.assets[] | select(.name == "ASSET") | .digest' | str replace 'ASSET' $asset)
  let result = (^gh release view $tag --repo $repository --json assets --jq $query | complete)
  if $result.exit_code != 0 { error make ($result.stderr | str trim) }
  let digest = ($result.stdout | str trim)
  if ($digest | is-empty) { error make $"No SHA-256 digest published for ($repository)/($tag)/($asset)" }
  let converted = (^nix hash convert --hash-algo sha256 --from base16 --to sri $digest | complete)
  if $converted.exit_code != 0 { error make ($converted.stderr | str trim) }
  $converted.stdout | str trim
}

export def latest-manifest-version [url: string, field: string] {
  let response = (http get $url)
  let manifest = if (($response | describe) == "string") { $response | from json } else { $response }
  $manifest | get $field
}
